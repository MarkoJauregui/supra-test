// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenSale
 * @author Marko Jauregui
 * @dev A smart contract for managing token sales.
 */

contract TokenSale is ReentrancyGuard, Ownable {
    IERC20 public immutable token;

    // Constants
    uint256 public constant PRESALE_CAP = 1000 ether;
    uint256 public constant PUBLIC_SALE_CAP = 5000 ether;
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;
    uint256 public constant MAX_CONTRIBUTION = 10 ether;
    uint256 public constant MINIMUM_CAP = 500 ether;

    // State variables
    bool public isPresaleActive;
    bool public isPublicSaleActive;
    bool public refundAvailable;
    uint256 public totalRaised;

    mapping(address => uint256) public contributions;

    // Events
    event ContributionMade(address indexed contributor, uint256 amount);
    event PublicSaleStarted();
    event PresaleEnded();
    event RefundEnabled();
    event RefundClaimed(address indexed contributor, uint256 amount);

    // Errors
    error InsufficientContribution();
    error MaxContributionCapReached();
    error ContributionExceedsCap();
    error SaleNotActive();
    error RefundNotAvailable();
    error InvalidAddress();
    error InvalidAmount();
    error PresaleStillActive();
    error PresaleAlreadyEnded();

    /**
     * @dev Constructor to initialize the contract.
     * @param _tokenAddress Address of the ERC20 token used for the sale.
     * @param _initialOwner Address of the initial owner of the contract.
     */
    constructor(
        address _tokenAddress,
        address _initialOwner
    ) Ownable(_initialOwner) {
        token = IERC20(_tokenAddress);
        isPresaleActive = true;
        isPublicSaleActive = false;
        refundAvailable = false;
    }

    /**
     * @dev Allows users to contribute Ether and receive tokens.
     */
    function contribute() external payable nonReentrant {
        if (msg.value < MIN_CONTRIBUTION) revert InsufficientContribution();
        if (msg.value > MAX_CONTRIBUTION) revert MaxContributionCapReached();

        if (isPresaleActive && totalRaised + msg.value >= PRESALE_CAP)
            revert ContributionExceedsCap();
        if (isPublicSaleActive && totalRaised + msg.value >= PUBLIC_SALE_CAP)
            revert ContributionExceedsCap();
        if (!isPresaleActive && !isPublicSaleActive) revert SaleNotActive();

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        uint256 tokenAmount = calculateTokenAmount(msg.value);
        token.transfer(msg.sender, tokenAmount);

        emit ContributionMade(msg.sender, msg.value);
    }

    /**
     * @dev Distributes tokens to an address.
     * @param to Address to receive tokens.
     * @param amount Amount of tokens to distribute.
     */
    function distributeTokens(address to, uint256 amount) external onlyOwner {
        if (to == address(0)) revert InvalidAddress();
        if (amount == 0) revert InvalidAmount();
        token.transfer(to, amount);
    }

    /**
     * @dev Ends the presale phase.
     */
    function endPresale() external onlyOwner {
        if (!isPresaleActive) revert PresaleAlreadyEnded();
        isPresaleActive = false;
        emit PresaleEnded();
    }

    /**
     * @dev Starts the public sale phase.
     */
    function startPublicSale() external onlyOwner {
        if (isPresaleActive) revert PresaleStillActive();
        isPublicSaleActive = true;
        emit PublicSaleStarted();
    }

    /**
     * @dev Enables refund if the minimum cap is not reached.
     */
    function enableRefund() external onlyOwner {
        if (totalRaised < MINIMUM_CAP) {
            refundAvailable = true;
            emit RefundEnabled();
        }
    }

    /**
     * @dev Claims a refund for the sender.
     */
    function claimRefund() external nonReentrant {
        if (!refundAvailable) revert RefundNotAvailable();
        uint256 amount = contributions[msg.sender];
        if (amount > 0) {
            contributions[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
            emit RefundClaimed(msg.sender, amount);
        }
    }

    /**
     * @dev Calculates the token amount based on the Ether amount.
     * @param _etherAmount Amount of Ether to convert to tokens.
     * @return The corresponding token amount.
     */
    function calculateTokenAmount(
        uint256 _etherAmount
    ) public pure returns (uint256) {
        uint256 rate = 100; // Example: 1 Ether = 100 tokens
        return _etherAmount * rate;
    }

    /**
     * @dev Checks if the presale phase is still active.
     * @return True if the presale is active, false otherwise.
     */
    function _isPresaleActive() public view returns (bool) {
        return isPresaleActive;
    }
}
