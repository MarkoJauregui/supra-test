# TokenSale Smart Contract

## Overview

The `TokenSale` contract manages token sales on the Ethereum blockchain, integrating features like presale and public sale phases, Ether contributions, token distribution, and refund functionalities.

## Key Features

- Presale and Public Sale Phases
- Contribution Tracking
- Refund Functionality
- Token Distribution
- Reentrancy Protection using OpenZeppelin's `ReentrancyGuard`

## Dependencies

- Solidity ^0.8.17
- OpenZeppelin Contracts: `ReentrancyGuard`, `Ownable`, `IERC20`

## Functions

- `contribute`
- `distributeTokens`
- `endPresale`
- `startPublicSale`
- `enableRefund`
- `claimRefund`
- `calculateTokenAmount`
- `_isPresaleActive`

## Events

- `ContributionMade`
- `PublicSaleStarted`
- `PresaleEnded`
- `RefundEnabled`
- `RefundClaimed`

## Errors

- `InsufficientContribution`
- `MaxContributionCapReached`
- `ContributionExceedsCap`
- `SaleNotActive`
- `RefundNotAvailable`
- `InvalidAddress`
- `InvalidAmount`
- `PresaleStillActive`
- `PresaleAlreadyEnded`

---

# TokenSale Testing Suite

## Overview

This suite tests the `TokenSale` contract's functionality, including contributions, sale phases, token distribution, and refunds.

## Key Tests

- `testSuccessfulContribution`
- `testFailContributionBelowMinimum`
- `testFailContributionAboveMaximum`
- `testPublicSaleTransition`
- `testRefundFunctionality`
- `testContributionEventEmission`
- `testApproachingPresaleCap`
- `testFailExceedPresaleCap`
- `testFailContributeDuringInactiveSale`
- `testFailDistributeTokensInvalidAddress`
- `testFailDistributeTokensInvalidAmount`
- `testExactMinimumContribution`
- `testExactMaximumContribution`

## Prerequisites

- Foundry framework
- Solidity ^0.8.17
