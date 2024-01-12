# MultiSigWallet Project

## Overview

The MultiSigWallet is a blockchain-based smart contract implemented on the Ethereum network. It is designed to enhance security and control for Ethereum transactions by requiring multiple confirmations from designated owners.

### Features

- Multi-signature functionality: Transactions require multiple confirmations from different owners.
- Role-based access control: Utilizes OpenZeppelin's AccessControl for managing owner roles.
- Ethereum transaction support: Send Ether and execute arbitrary transactions.

## Installation

### Prerequisites

- Foundry for smart contract compilation and testing

### Setup

Clone the repository and install dependencies:

```
git clone https://github.com/your-github/MultiSigWallet.git
cd MultiSigWallet
forge install
```

## Usage

### Interacting with the Contract

You can interact with the contract using Foundry or Ethers.js.

### Running Tests

Execute the test suite using:

- forge test

## Contract Functions

- `submitTransaction`: Submit a transaction for confirmation by the owners.
- `confirmTransaction`: Confirm a submitted transaction.
- `revokeConfirmation`: Revoke a previously made confirmation.
- `executeTransaction`: Execute a confirmed transaction.
- `getOwners`: Retrieve the list of owners.
- `getTransactionCount`: Get the total number of transactions.
- `getTransaction`: Get details of a specific transaction.
- `isConfirmed`: Check if a transaction is confirmed by a specific owner.

## Security

The contract uses OpenZeppelin's contracts for standard, secure implementations of common functionalities like AccessControl. It's recommended to conduct a thorough audit before using it in a production environment.

## Authors

- Marko Jauregui
