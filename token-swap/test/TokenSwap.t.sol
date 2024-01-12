// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/TokenSwap.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract TokenSwapTest is Test {
    TokenSwap tokenSwap;
    TokenA tokenA;
    TokenB tokenB;
    address user = address(1);

    function setUp() public {
        tokenA = new TokenA(1e24); // 1 million Token A
        tokenB = new TokenB(1e24); // 1 million Token B
        tokenSwap = new TokenSwap(
            address(tokenA),
            address(tokenB),
            address(this)
        );

        tokenA.transfer(user, 1e21); // 1000 Token A to user
        tokenB.transfer(user, 1e21); // 1000 Token B to user
        tokenA.transfer(address(tokenSwap), 1e21); // 1000 Token A to TokenSwap
        tokenB.transfer(address(tokenSwap), 1e21); // 1000 Token B to TokenSwap
    }

    function testSwapAforB() public {
        uint256 initialBalanceB = tokenB.balanceOf(user);
        uint256 amountA = 2e18; // 2 Token A
        uint256 expectedIncreaseInB = amountA / 2; // 1 Token B

        vm.startPrank(user);
        tokenA.approve(address(tokenSwap), amountA);
        tokenSwap.swapAforB(amountA);
        vm.stopPrank();

        uint256 finalBalanceB = tokenB.balanceOf(user);
        assertEq(finalBalanceB, initialBalanceB + expectedIncreaseInB);
    }

    function testSwapBforA() public {
        uint256 initialBalanceA = tokenA.balanceOf(user);
        uint256 amountB = 1e18; // 1 Token B
        uint256 expectedIncreaseInA = amountB * 2; // 2 Token A

        vm.startPrank(user);
        tokenB.approve(address(tokenSwap), amountB);
        tokenSwap.swapBforA(amountB);
        vm.stopPrank();

        uint256 finalBalanceA = tokenA.balanceOf(user);
        assertEq(finalBalanceA, initialBalanceA + expectedIncreaseInA);
    }

    function testFailSwapAforBWithInsufficientUserBalance() public {
        uint256 amountA = tokenA.balanceOf(user) + 1; // More than the user has

        vm.startPrank(user);
        tokenA.approve(address(tokenSwap), amountA);
        tokenSwap.swapAforB(amountA); // Should fail
        vm.stopPrank();
    }

    function testFailSwapBforAWithInsufficientContractBalance() public {
        uint256 amountB = tokenB.balanceOf(address(tokenSwap)) + 1; // More than the contract has

        vm.startPrank(user);
        tokenB.approve(address(tokenSwap), amountB);
        tokenSwap.swapBforA(amountB); // Should fail
        vm.stopPrank();
    }

    function testFailSwapBforAWithInvalidAmount() public {
        uint256 amountB = 1; // Set to a value that results in less than MINIMUM_SWAP_THRESHOLD of Token A

        vm.startPrank(user);
        tokenB.approve(address(tokenSwap), amountB);
        tokenSwap.swapBforA(amountB); // Should fail
        vm.stopPrank();
    }

    function testFailSwapBforAWithInsufficientUserBalance() public {
        uint256 amountB = tokenB.balanceOf(user) + 1; // More than the user has

        vm.startPrank(user);
        tokenB.approve(address(tokenSwap), amountB);
        tokenSwap.swapBforA(amountB); // Should fail
        vm.stopPrank();
    }

    function testFailSwapAforBWithInsufficientContractBalance() public {
        uint256 amountA = (tokenB.balanceOf(address(tokenSwap)) * 2) + 1; // More than the contract can swap

        vm.startPrank(user);
        tokenA.approve(address(tokenSwap), amountA);
        tokenSwap.swapAforB(amountA); // Should fail
        vm.stopPrank();
    }

    function testFailSwapAforBWithInvalidAmount() public {
        uint256 amountA = 1; // This should result in 0 Token B, triggering the error

        vm.startPrank(user);
        tokenA.approve(address(tokenSwap), amountA);
        tokenSwap.swapAforB(amountA); // Should fail and revert
        vm.stopPrank();
    }
}
