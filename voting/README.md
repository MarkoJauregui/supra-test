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
git clone https://github.com/your-github/DecentralizedVoting.git
cd DecentralizedVoting
forge install
```

## Usage

### Interacting with the Contract

You can interact with the contract using Foundry or Ethers.js.

### Running Tests

Execute the test suite using:

- forge test

## Contract Functions

- registerVoter(): Registers the caller as a voter.
- addCandidate(string memory \_name): Adds a new candidate (only callable by the contract owner).
- vote(uint \_candidateId): Casts a vote for a specified candidate (only callable by registered voters).
- getCandidateVoteCount(uint \_candidateId): Returns the current vote count for a specified candidate.

## Authors

- Marko Jauregui
