// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MultisigWallet is AccessControl {
    // Type Declarations

    // State Variables
    address[] private s_owners;
    uint256 private s_threshold;
    mapping(uint256 => Transaction) private s_transactions;
    mapping(address => bool) private s_isOwner;

    // Roles
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    // Events

    // Errors
    error MultisigWallet__Unauthorized();
    error MultisigWallet__InvalidOperation();

    // Constructor
    constructor(address[] memory _owners, uint256 _threshold) {
        // Initialization logic
    }

    // Functions

    // Internal Functions
}
