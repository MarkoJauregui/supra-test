// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error InsufficientContribution();
error ContributionExceedsCap();
error SaleNotActive();
error Unauthorized();
error RefundNotAvailable();

contract TokenSale {
    IERC20 public token;

    address public owner;
    uint256 public presaleCap;
    uint256 public publicSaleCap;
    uint256 public minimumContribution;
    uint256 public maximumContribution;
    bool public isPresaleActive;
    bool public isPublicSaleActive;
    uint256 public totalRaised;

    mapping(address => uint256) public contributions;

    constructor(
        address _tokenAddress,
        uint256 _presaleCap,
        uint256 _publicSaleCap,
        uint256 _minContribution,
        uint256 _maxContribution
    ) {
        token = IERC20(_tokenAddress);
        owner = msg.sender;
        presaleCap = _presaleCap;
        publicSaleCap = _publicSaleCap;
        minimumContribution = _minContribution;
        maximumContribution = _maxContribution;
        isPresaleActive = true;
        isPublicSaleActive = false;
    }

    function contribute() external payable {
        if (msg.value < minimumContribution || msg.value > maximumContribution)
            revert InsufficientContribution();
        if (isPresaleActive && totalRaised + msg.value > presaleCap)
            revert ContributionExceedsCap();
        if (isPublicSaleActive && totalRaised + msg.value > publicSaleCap)
            revert ContributionExceedsCap();
        if (!isPresaleActive && !isPublicSaleActive) revert SaleNotActive();

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        // Calculate and distribute tokens
        uint256 tokenAmount = calculateTokenAmount(msg.value);
        token.transfer(msg.sender, tokenAmount);
    }

    function calculateTokenAmount(
        uint256 _etherAmount
    ) private view returns (uint256) {
        // Implement token calculation logic
    }

    function startPublicSale() external {
        if (msg.sender != owner) revert Unauthorized();
        isPresaleActive = false;
        isPublicSaleActive = true;
    }

    function distributeTokens(address _to, uint256 _amount) external {
        if (msg.sender != owner) revert Unauthorized();
        token.transfer(_to, _amount);
    }

    function claimRefund() external {
        // Implement refund logic
    }

    // Additional functions as needed
}
