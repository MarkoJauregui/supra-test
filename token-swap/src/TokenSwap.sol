// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TokenSwap Contract
/// @notice This contract allows users to swap between two ERC20 tokens (Token A and Token B) at a fixed rate.
contract TokenSwap is Ownable, ReentrancyGuard {
    // State Variables
    IERC20 private s_tokenA;
    IERC20 private s_tokenB;

    // Constants
    uint256 private constant SWAP_RATE = 2; // Rate for both A to B and B to A swaps
    uint256 private constant MINIMUM_SWAP_THRESHOLD = 1e18; // Minimum amount of Token A to be received

    // Events
    event SwapAforB(address indexed user, uint256 amountA, uint256 amountB);
    event SwapBforA(address indexed user, uint256 amountB, uint256 amountA);

    // Errors
    error TokenSwap__InsufficientBalance(
        string token,
        uint256 required,
        uint256 available
    );
    error TokenSwap__InvalidAmount();

    /// @notice Constructor to create TokenSwap
    /// @param tokenA Address of the first token (Token A)
    /// @param tokenB Address of the second token (Token B)
    /// @param initialOwner Address of the initial owner
    constructor(
        address tokenA,
        address tokenB,
        address initialOwner
    ) Ownable(initialOwner) {
        s_tokenA = IERC20(tokenA);
        s_tokenB = IERC20(tokenB);
    }

    /// @notice Swap Token A for Token B
    /// @param amountA Amount of Token A to swap
    function swapAforB(uint256 amountA) external nonReentrant {
        uint256 amountB = amountA / SWAP_RATE;
        if (amountB < MINIMUM_SWAP_THRESHOLD) {
            revert TokenSwap__InvalidAmount();
        }
        if (s_tokenA.balanceOf(msg.sender) < amountA) {
            revert TokenSwap__InsufficientBalance(
                "Token A",
                amountA,
                s_tokenA.balanceOf(msg.sender)
            );
        }
        if (s_tokenB.balanceOf(address(this)) < amountB) {
            revert TokenSwap__InsufficientBalance(
                "Token B",
                amountB,
                s_tokenB.balanceOf(address(this))
            );
        }

        _swap(s_tokenA, s_tokenB, amountA, amountB);
        emit SwapAforB(msg.sender, amountA, amountB);
    }

    /// @notice Swap Token B for Token A
    /// @param amountB Amount of Token B to swap
    function swapBforA(uint256 amountB) external nonReentrant {
        uint256 amountA = amountB * SWAP_RATE;
        if (amountA < MINIMUM_SWAP_THRESHOLD) {
            revert TokenSwap__InvalidAmount();
        }
        if (s_tokenB.balanceOf(msg.sender) < amountB) {
            revert TokenSwap__InsufficientBalance(
                "Token B",
                amountB,
                s_tokenB.balanceOf(msg.sender)
            );
        }
        if (s_tokenA.balanceOf(address(this)) < amountA) {
            revert TokenSwap__InsufficientBalance(
                "Token A",
                amountA,
                s_tokenA.balanceOf(address(this))
            );
        }

        _swap(s_tokenB, s_tokenA, amountB, amountA);
        emit SwapBforA(msg.sender, amountB, amountA);
    }

    /// @dev Internal function to handle token swaps
    /// @param tokenIn Token being sent
    /// @param tokenOut Token being received
    /// @param amountIn Amount of tokenIn being sent
    /// @param amountOut Amount of tokenOut to be received
    function _swap(
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 amountOut
    ) private {
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }
}
