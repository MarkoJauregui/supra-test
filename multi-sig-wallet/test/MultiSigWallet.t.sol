// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultisigWallet wallet;
    address[] owners;
    uint256 threshold = 2;

    function setUp() public {
        // Initialize owners array
        owners.push(address(1));
        owners.push(address(2));
        owners.push(address(3));

        // Deploy the MultisigWallet contract
        wallet = new MultisigWallet(owners, threshold);
    }

    function testDeployment() public {
        // Test correct deployment
        assertEq(wallet.getOwners().length, 3);
        assertEq(wallet.getTransactionCount(), 0);
    }
}
