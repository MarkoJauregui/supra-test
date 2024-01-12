// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Multi-Signature Wallet
/// @author Marko Jauregui
/// @notice Implements a multi-signature wallet where transactions require multiple confirmations.
/// @dev Inherits from OpenZeppelin's AccessControl for role management.
contract MultiSigWallet is AccessControl {
    /// @dev Struct to represent a transaction.
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    /// @dev Array of owner addresses.
    address[] private s_owners;

    /// @dev Required number of confirmations for a transaction.
    uint256 private s_threshold;

    /// @dev Total number of transactions.
    uint256 private s_transactionCount;

    /// @dev Mapping from transaction ID to Transaction struct.
    mapping(uint256 => Transaction) private s_transactions;

    /// @dev Mapping to keep track of owners.
    mapping(address => bool) private s_isOwner;

    /// @dev Mapping from transaction ID to mapping of owner addresses to confirmation status.
    mapping(uint256 => mapping(address => bool)) private s_approvals;

    /// @dev Role identifier for owners.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @notice Emitted when Ether is deposited into the wallet.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /// @notice Emitted when a transaction is submitted.
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );

    /// @notice Emitted when a transaction is confirmed by an owner.
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when a confirmation is revoked by an owner.
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    /// @notice Emitted when a transaction is executed.
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    /// @notice Custom errors for revert statements.
    error MultisigWallet__Unauthorized();
    error MultisigWallet__TransactionAlreadyExecuted();
    error MultisigWallet__TransactionDoesNotExist();
    error MultisigWallet__NotEnoughConfirmations();
    error MultisigWallet__InvalidOperation();
    error MultisigWallet__TransactionFailed();

    /// @notice Constructor to initialize the wallet with a set of owners and a threshold.
    /// @param _owners Array of owner addresses.
    /// @param _threshold Number of required confirmations for a transaction.
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

    /// @notice Submits a new transaction.
    /// @param _to Recipient address of the transaction.
    /// @param _value Amount of Ether to send.
    /// @param _data Call data to be sent with the transaction.
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

    /// @notice Confirms a transaction by an owner.
    /// @param _txIndex Index of the transaction to confirm.
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

    /// @notice Executes a confirmed transaction.
    /// @param _txIndex Index of the transaction to execute.
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

    /// @notice Revokes a confirmation made by an owner.
    /// @param _txIndex Index of the transaction to revoke confirmation for.
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

    /// @notice Returns the list of owners.
    /// @return Array of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return s_owners;
    }

    /// @notice Returns the total number of transactions.
    /// @return Total number of transactions.
    function getTransactionCount() public view returns (uint256) {
        return s_transactionCount;
    }

    /// @notice Returns details of a specific transaction.
    /// @param _txIndex Index of the transaction.
    /// @return Transaction struct containing details of the transaction.
    function getTransaction(
        uint256 _txIndex
    ) public view returns (Transaction memory) {
        return s_transactions[_txIndex];
    }

    /// @notice Checks if a transaction is confirmed by a specific owner.
    /// @param _txIndex Index of the transaction.
    /// @param _owner Address of the owner.
    /// @return True if the transaction is confirmed by the owner, false otherwise.
    function isConfirmed(
        uint256 _txIndex,
        address _owner
    ) public view returns (bool) {
        return s_approvals[_txIndex][_owner];
    }

    /// @notice Returns the number of confirmations for a specific transaction.
    /// @param _txIndex Index of the transaction.
    /// @return Number of confirmations for the transaction.
    function getConfirmationCount(
        uint256 _txIndex
    ) public view returns (uint256) {
        return s_transactions[_txIndex].numConfirmations;
    }

    /// @notice Returns the constant OWNER_ROLE.
    /// @return The keccak256 hash of "OWNER_ROLE".
    function getOwnerRole() public pure returns (bytes32) {
        return OWNER_ROLE;
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {}
}
