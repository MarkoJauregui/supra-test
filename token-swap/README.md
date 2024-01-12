# Decentralized Voting System

## Overview

The Decentralized Voting System is a blockchain-based voting system implemented as a smart contract on the Ethereum network. It provides a transparent, secure, and accessible platform for conducting elections or polls.

### Features

- User registration for voting
- Adding candidates by the contract owner
- Voting for candidates by registered users
- Transparent and publicly accessible vote tally

## Installation

### Prerequisites

- Node.js
- Foundry for smart contract compilation and testing

### Setup

Clone the repository and install dependencies:

```
git clone https://github.com/your-github/TokenSwap.git
cd TokenSwap
forge install
```

## Usage

### Interacting with the Contract

You can interact with the contract using Foundry or Ethers.js.

### Running Tests

Execute the test suite using:

- forge test

## Contract Functions

- swapAforB(uint256 amountA): Swaps a specified amount of Token A for Token B.
- swapBforA(uint256 amountB): Swaps a specified amount of Token B for Token A.
- \_swap(IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn, uint256 amountOut): Internal function to handle the token swap logic.

## Security

The contract includes reentrancy guards and follows best practices for smart contract development. However, it's recommended to conduct a thorough audit before using it in a production environment.

## Authors

- Marko Jauregui
