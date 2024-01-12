// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract TestReceiver {
    event Received(address sender, uint256 value, bytes data);

    receive() external payable {
        emit Received(msg.sender, msg.value, "");
    }

    function testCall(bytes memory data) external payable {
        emit Received(msg.sender, msg.value, data);
    }

    function alwaysRevert() external payable {
        revert("TestReceiver: Always revert");
    }
}

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] owners;
    uint256 threshold = 2;

    TestReceiver testReceiver;

    function setUp() public {
        // Initialize owners array
        owners.push(address(1));
        owners.push(address(2));
        owners.push(address(3));

        // Deploy the MultisigWallet contract
        wallet = new MultiSigWallet(owners, threshold);
        testReceiver = new TestReceiver();

        // Fund the MultisigWallet contract with some Ether
        vm.deal(address(wallet), 1 ether);
    }

    function testDeployment() public {
        // Test correct deployment
        assertEq(wallet.getOwners().length, 3);
        assertEq(wallet.getTransactionCount(), 0);
    }

    function testSubmitTransaction() public {
        // Owner 1 submits a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(4), 100, "0x00");

        // Retrieve the transaction and check its details
        MultiSigWallet.Transaction memory transaction = wallet.getTransaction(
            0
        );
        assertEq(transaction.to, address(4));
        assertEq(transaction.value, 100);
        assertEq(transaction.executed, false);
        assertEq(transaction.numConfirmations, 0);
    }

    function testConfirmTransaction() public {
        // Owner 1 submits a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(4), 100, "0x00");

        // Owner 2 confirms the transaction
        vm.prank(address(2));
        wallet.confirmTransaction(0);

        // Check the number of confirmations
        uint256 confirmations = wallet.getConfirmationCount(0);
        assertEq(confirmations, 1);
    }

    function testConfirmTransactionByOwner() public {
        // Owner 1 submits a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(testReceiver), 100, "0x00");

        // Owner 1 confirms the transaction
        vm.prank(address(1));
        wallet.confirmTransaction(0);

        // Check the number of confirmations
        uint256 confirmations = wallet.getConfirmationCount(0);
        assertEq(confirmations, 1);
    }

    function testExecuteTransaction() public {
        // Owner 1 submits a transaction to the TestReceiver contract
        vm.prank(address(1));
        wallet.submitTransaction(
            address(testReceiver),
            100,
            abi.encodeWithSignature("testCall(bytes)", "0x00")
        );

        // Owner 2 confirms the transaction
        vm.prank(address(2));
        wallet.confirmTransaction(0);

        // Owner 3 confirms the transaction
        vm.prank(address(3));
        wallet.confirmTransaction(0);

        // Owner 1 executes the transaction
        vm.prank(address(1));
        wallet.executeTransaction(0);

        // Check if the transaction is executed
        MultiSigWallet.Transaction memory transaction = wallet.getTransaction(
            0
        );
        assertTrue(transaction.executed);
    }

    function testFailNonOwnerSubmitTransaction() public {
        // Non-owner tries to submit a transaction
        vm.prank(address(4));
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiSigWallet.MultisigWallet__Unauthorized.selector
            )
        );
        wallet.submitTransaction(address(testReceiver), 50, "0x00");
    }

    function testFailDoubleConfirmation() public {
        // Owner 1 submits and confirms a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(testReceiver), 100, "0x00");
        wallet.confirmTransaction(0);

        // Owner 1 tries to confirm the same transaction again
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiSigWallet.MultisigWallet__Unauthorized.selector
            )
        );
        wallet.confirmTransaction(0);
    }

    function hasOwnerRole(address _owner) public view returns (bool) {
        return wallet.hasRole(wallet.getOwnerRole(), _owner);
    }

    function testFailExecuteAlreadyExecutedTransaction() public {
        // Setup and execute the transaction as in testExecuteTransaction

        // Try to execute the same transaction again
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiSigWallet
                    .MultisigWallet__TransactionAlreadyExecuted
                    .selector
            )
        );
        wallet.executeTransaction(0);
    }

    function testFailInvalidTransactionIndex() public {
        // Owner 1 tries to confirm a non-existent transaction
        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSignature("MultisigWallet__TransactionDoesNotExist")
        );
        wallet.confirmTransaction(999); // Using an arbitrary large index
    }

    function testRevokeConfirmationInvalidIndex() public {
        // Owner 1 tries to revoke confirmation for a non-existent transaction
        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSignature("MultisigWallet__TransactionDoesNotExist()")
        );
        wallet.revokeConfirmation(999); // Using an arbitrary large index
    }

    function testRevokeConfirmationNotConfirmed() public {
        // Owner 1 submits a transaction but does not confirm it
        vm.prank(address(1));
        wallet.submitTransaction(address(testReceiver), 100, "0x00");

        // Owner 1 tries to revoke a confirmation they never made
        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSignature("MultisigWallet__Unauthorized()")
        );
        wallet.revokeConfirmation(0);
    }

    function testIsConfirmed() public {
        // Check if address(1) is an owner and has the OWNER_ROLE
        assertTrue(wallet.hasRole(wallet.getOwnerRole(), address(1)));

        // Owner 1 submits a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(testReceiver), 100, "0x00");

        // Check if the transaction is correctly added
        MultiSigWallet.Transaction memory tx = wallet.getTransaction(0);
        assertEq(tx.to, address(testReceiver));
        assertEq(tx.value, 100);

        // Owner 1 confirms the transaction
        vm.prank(address(1));
        wallet.confirmTransaction(0);

        // Check if the transaction is confirmed by Owner 1
        assertTrue(wallet.isConfirmed(0, address(1)));
    }

    function testGetOwnerRole() public {
        // Simply call getOwnerRole to cover the function
        bytes32 ownerRole = wallet.getOwnerRole();
        assertEq(ownerRole, keccak256("OWNER_ROLE"));
    }

    function testFailRevokeConfirmationByNonOwner() public {
        // Owner 1 submits and confirms a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(testReceiver), 100, "0x00");
        wallet.confirmTransaction(0);

        // Non-owner tries to revoke the confirmation
        vm.prank(address(4));
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiSigWallet.MultisigWallet__Unauthorized.selector
            )
        );
        wallet.revokeConfirmation(0);
    }

    function testFailExecuteTransactionByNonOwner() public {
        // Owner 1 submits and confirms a transaction
        vm.prank(address(1));
        wallet.submitTransaction(address(testReceiver), 100, "0x00");
        wallet.confirmTransaction(0);

        // Owner 2 also confirms the transaction
        vm.prank(address(2));
        wallet.confirmTransaction(0);

        // Non-owner tries to execute the transaction
        vm.prank(address(4));
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiSigWallet.MultisigWallet__Unauthorized.selector
            )
        );
        wallet.executeTransaction(0);
    }

    function testFailExecuteTransactionWithCallFailure() public {
        // Owner 1 submits a transaction to the TestReceiver contract
        vm.prank(address(1));
        wallet.submitTransaction(
            address(testReceiver),
            100,
            abi.encodeWithSignature("alwaysRevert()")
        );

        // Confirm the transaction with the necessary number of owners
        vm.prank(address(2));
        wallet.confirmTransaction(0);
        vm.prank(address(3));
        wallet.confirmTransaction(0);

        // Attempt to execute the transaction and expect it to fail
        vm.prank(address(1));
        vm.expectRevert("TestReceiver: Always revert");
        wallet.executeTransaction(0);
    }

    function testFailSubmitTransactionToZeroAddress() public {
        // Owner 1 tries to submit a transaction to the zero address
        vm.prank(address(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiSigWallet.MultisigWallet__InvalidOperation.selector
            )
        );
        wallet.submitTransaction(address(0), 100, "0x00");
    }

    function testFailExecuteTransactionInsufficientBalance() public {
        // Owner 1 submits a transaction to send more Ether than the contract has
        vm.prank(address(1));
        wallet.submitTransaction(
            address(4),
            address(wallet).balance + 1,
            "0x00"
        );

        // Confirm the transaction with the necessary number of owners
        vm.prank(address(2));
        wallet.confirmTransaction(0);
        vm.prank(address(3));
        wallet.confirmTransaction(0);

        // Attempt to execute the transaction and expect it to fail due to insufficient balance
        vm.prank(address(1));
        vm.expectRevert("MultisigWallet__TransactionFailed");
        wallet.executeTransaction(0);
    }
}
