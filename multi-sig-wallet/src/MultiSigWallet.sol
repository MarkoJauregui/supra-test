// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MultisigWallet is AccessControl {
    // Type Declarations
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    // State Variables
    address[] private s_owners;
    uint256 private s_threshold;
    uint256 private s_transactionCount;
    mapping(uint256 => Transaction) private s_transactions;
    mapping(address => bool) private s_isOwner;
    mapping(uint256 => mapping(address => bool)) private s_approvals;

    // Roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Events
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    // Errors
    error MultisigWallet__Unauthorized();
    error MultisigWallet__TransactionAlreadyExecuted();
    error MultisigWallet__TransactionDoesNotExist();
    error MultisigWallet__NotEnoughConfirmations();
    error MultisigWallet__InvalidOperation();
    error MultisigWallet__TransactionFailed();

    // Constructor
    // Constructor
    constructor(address[] memory _owners, uint256 _threshold) {
        if (_owners.length == 0) revert MultisigWallet__InvalidOperation();
        if (_threshold == 0 || _threshold > _owners.length)
            revert MultisigWallet__InvalidOperation();

        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == address(0) || s_isOwner[_owners[i]]) {
                revert MultisigWallet__InvalidOperation();
            }

            s_isOwner[_owners[i]] = true;
            s_owners.push(_owners[i]);
            _grantRole(OWNER_ROLE, _owners[i]);
        }

        s_threshold = _threshold;
    }

    // Functions

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyRole(OWNER_ROLE) {
        uint256 txIndex = s_transactionCount;

        s_transactions[txIndex] = Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false,
            numConfirmations: 0
        });

        s_transactionCount++;

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransaction(uint256 _txIndex) public onlyRole(OWNER_ROLE) {
        if (_txIndex >= s_transactionCount)
            revert MultisigWallet__TransactionDoesNotExist();
        if (s_transactions[_txIndex].executed)
            revert MultisigWallet__TransactionAlreadyExecuted();
        if (s_approvals[_txIndex][msg.sender])
            revert MultisigWallet__Unauthorized();

        s_approvals[_txIndex][msg.sender] = true;
        s_transactions[_txIndex].numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex) public onlyRole(OWNER_ROLE) {
        if (_txIndex >= s_transactionCount)
            revert MultisigWallet__TransactionDoesNotExist();
        if (s_transactions[_txIndex].executed)
            revert MultisigWallet__TransactionAlreadyExecuted();
        if (s_transactions[_txIndex].numConfirmations < s_threshold)
            revert MultisigWallet__NotEnoughConfirmations();

        Transaction storage transaction = s_transactions[_txIndex];
        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert MultisigWallet__TransactionFailed();

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex) public onlyRole(OWNER_ROLE) {
        if (_txIndex >= s_transactionCount)
            revert MultisigWallet__TransactionDoesNotExist();
        if (s_transactions[_txIndex].executed)
            revert MultisigWallet__TransactionAlreadyExecuted();
        if (!s_approvals[_txIndex][msg.sender])
            revert MultisigWallet__Unauthorized();

        s_approvals[_txIndex][msg.sender] = false;
        s_transactions[_txIndex].numConfirmations -= 1;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // Returns the list of owners
    function getOwners() public view returns (address[] memory) {
        return s_owners;
    }

    // Returns the total number of transactions
    function getTransactionCount() public view returns (uint256) {
        return s_transactionCount;
    }

    // Returns details of a specific transaction
    function getTransaction(
        uint256 _txIndex
    ) public view returns (Transaction memory) {
        return s_transactions[_txIndex];
    }

    // Checks if a transaction is confirmed by a specific owner
    function isConfirmed(
        uint256 _txIndex,
        address _owner
    ) public view returns (bool) {
        return s_approvals[_txIndex][_owner];
    }

    // Returns the number of confirmations for a specific transaction
    function getConfirmationCount(
        uint256 _txIndex
    ) public view returns (uint256) {
        return s_transactions[_txIndex].numConfirmations;
    }
}
