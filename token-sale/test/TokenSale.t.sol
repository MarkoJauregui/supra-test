// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/TokenSale.sol";
import "../src/TestToken.sol";

contract TokenSaleTest is Test {
    TokenSale tokenSale;
    TestToken token;

    uint256 public constant PRESALE_CAP = 1000 ether;
    uint256 public constant PUBLIC_SALE_CAP = 5000 ether;
    uint256 public constant MIN_CONTRIBUTION = 0.1 ether;
    uint256 public constant MAX_CONTRIBUTION = 10 ether;
    uint256 public constant MINIMUM_CAP = 500 ether;

    event ContributionMade(address indexed contributor, uint256 amount);

    function setUp() public {
        token = new TestToken(1e24); // Ensure a large enough initial supply, e.g., 1 million tokens
        tokenSale = new TokenSale(address(token), address(this));
        token.transfer(address(tokenSale), 1e23); // Transfer a large number of tokens to the TokenSale contract
    }

    function testSuccessfulContribution() public {
        // Arrange
        uint256 contributionAmount = 1 ether;
        uint256 initialUserTokenBalance = token.balanceOf(address(this));
        uint256 rate = tokenSale.calculateTokenAmount(1 ether);

        // Act
        vm.deal(address(this), contributionAmount);
        tokenSale.contribute{value: contributionAmount}();

        // Assert
        uint256 finalUserTokenBalance = token.balanceOf(address(this));
        assertEq(
            finalUserTokenBalance,
            initialUserTokenBalance + rate,
            "Token balance did not increase correctly"
        );
        assertEq(
            address(tokenSale).balance,
            contributionAmount,
            "Contract Ether balance did not increase correctly"
        );
    }

    function testFailContributionBelowMinimum() public {
        // Arrange
        uint256 lowContribution = 0.05 ether; // A value lower than the MIN_CONTRIBUTION

        // Act & Assert
        vm.deal(address(this), lowContribution);
        tokenSale.contribute{value: lowContribution}();
    }

    function testFailContributionAboveMaximum() public {
        // Arrange
        uint256 highContribution = 11 ether; // A value higher than the MAX_CONTRIBUTION

        // Act & Assert
        vm.deal(address(this), highContribution);
        tokenSale.contribute{value: highContribution}();
    }

    function testPublicSaleTransition() public {
        // End presale first
        tokenSale.endPresale();

        // Start public sale
        tokenSale.startPublicSale();

        // Assert conditions
        assertTrue(
            tokenSale.isPublicSaleActive(),
            "Public sale should be active"
        );
        assertFalse(
            tokenSale.isPresaleActive(),
            "Presale should not be active"
        );
    }

    function testRefundFunctionality() public {
        // Arrange
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = (MINIMUM_CAP - 10 ether) /
            contributionAmount;

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Enable refund
        tokenSale.enableRefund();

        // Act & Assert for one of the contributors
        address refundClaimant = address(
            uint160(uint256(keccak256(abi.encodePacked(uint256(0)))))
        );
        uint256 initialBalance = refundClaimant.balance;
        vm.prank(refundClaimant);
        tokenSale.claimRefund();

        uint256 finalBalance = refundClaimant.balance;
        assertEq(
            finalBalance,
            initialBalance + contributionAmount,
            "Refund was not successful"
        );
    }

    function testContributionEventEmission() public {
        // Arrange
        uint256 contributionAmount = 1 ether;
        vm.deal(address(this), contributionAmount);

        // Act & Assert
        vm.expectEmit(true, true, false, false); // Set expectations for the event
        // The following line is for specifying the expected event format
        emit ContributionMade(address(this), contributionAmount);
        tokenSale.contribute{value: contributionAmount}(); // This call should emit the event
    }

    function testApproachingPresaleCap() public {
        // Arrange
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = PRESALE_CAP / MAX_CONTRIBUTION - 1; // One less to stay below the cap

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Act & Assert
        assertLt(
            tokenSale.totalRaised(),
            PRESALE_CAP,
            "Total raised should be less than presale cap"
        );
    }

    function testFailExceedPresaleCap() public {
        // Arrange
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = PRESALE_CAP / MAX_CONTRIBUTION;

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Act & Assert
        address lastContributor = address(
            uint160(uint256(keccak256(abi.encodePacked(numberOfContributions))))
        );
        vm.deal(lastContributor, contributionAmount);
        vm.expectRevert(bytes("ContributionExceedsCap()"));
        vm.prank(lastContributor);
        tokenSale.contribute{value: contributionAmount}();
    }

    function testFailContributeDuringInactiveSale() public {
        // Arrange
        // Ensure both presale and public sale are inactive
        tokenSale.startPublicSale(); // Start and end the public sale

        // Act & Assert
        uint256 contributionAmount = 1 ether;
        vm.deal(address(this), contributionAmount);
        vm.expectRevert(bytes("SaleNotActive()"));
        tokenSale.contribute{value: contributionAmount}();
    }

    function testFailExceedPublicSaleCap() public {
        // Start public sale
        tokenSale.startPublicSale();

        // Arrange contributions to reach just below the PUBLIC_SALE_CAP
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = (PUBLIC_SALE_CAP - 10 ether) /
            contributionAmount;

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Act & Assert: Exceeding the PUBLIC_SALE_CAP should fail
        uint256 excessContribution = 11 ether; // Exceeds MAX_CONTRIBUTION to ensure failure
        vm.deal(address(this), excessContribution);
        vm.expectRevert(bytes("ContributionExceedsCap()"));
        tokenSale.contribute{value: excessContribution}();
    }

    function testFailExceedPresaleCapBeforePublicSale() public {
        // Arrange contributions to reach just below the PRESALE_CAP
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = (PRESALE_CAP - 10 ether) /
            contributionAmount;

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Act & Assert: Exceeding the PRESALE_CAP should fail
        uint256 excessContribution = 11 ether; // Exceeds MAX_CONTRIBUTION to ensure failure
        vm.deal(address(this), excessContribution);
        vm.expectRevert(bytes("ContributionExceedsCap()"));
        tokenSale.contribute{value: excessContribution}();
    }

    function testFailDistributeTokensInvalidAddress() public {
        vm.expectRevert(bytes("InvalidAddress()"));
        tokenSale.distributeTokens(address(0), 1000);
    }

    function testFailDistributeTokensInvalidAmount() public {
        vm.expectRevert(bytes("InvalidAmount()"));
        tokenSale.distributeTokens(address(this), 0);
    }

    function testFailExceedPresaleCapDuringPresale() public {
        // Arrange
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = PRESALE_CAP / MAX_CONTRIBUTION;

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Act & Assert: Exceeding the PRESALE_CAP should fail
        uint256 excessContribution = 1 ether; // Any positive amount to exceed the cap
        vm.deal(address(this), excessContribution);
        vm.expectRevert(bytes("ContributionExceedsCap()"));
        tokenSale.contribute{value: excessContribution}();
    }

    function testFailExceedPublicSaleCapDuringPublicSale() public {
        // Start public sale
        tokenSale.startPublicSale();

        // Arrange contributions to reach just below the PUBLIC_SALE_CAP
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = PUBLIC_SALE_CAP / MAX_CONTRIBUTION;

        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }

        // Act & Assert: Exceeding the PUBLIC_SALE_CAP should fail
        uint256 excessContribution = 1 ether; // Any positive amount to exceed the cap
        vm.deal(address(this), excessContribution);
        vm.expectRevert(bytes("ContributionExceedsCap()"));
        tokenSale.contribute{value: excessContribution}();
    }

    function testFailContributeWhenSaleNotActive() public {
        // Arrange
        // Ensure both presale and public sale are inactive
        tokenSale.startPublicSale(); // Start and end the public sale

        // Act & Assert
        uint256 contributionAmount = 1 ether;
        vm.deal(address(this), contributionAmount);
        vm.expectRevert(bytes("SaleNotActive()"));
        tokenSale.contribute{value: contributionAmount}();
    }

    function testExactMinimumContribution() public {
        uint256 contributionAmount = MIN_CONTRIBUTION;
        vm.deal(address(this), contributionAmount);
        tokenSale.contribute{value: contributionAmount}();
        // Add assertions to check if the contribution was successful
    }

    function testExactMaximumContribution() public {
        uint256 contributionAmount = MAX_CONTRIBUTION;
        vm.deal(address(this), contributionAmount);
        tokenSale.contribute{value: contributionAmount}();
        // Add assertions to check if the contribution was successful
    }

    function testFailExceedPresaleCap2() public {
        // Arrange contributions to reach just below the PRESALE_CAP
        uint256 contributionAmount = MAX_CONTRIBUTION;
        uint256 numberOfContributions = PRESALE_CAP / MAX_CONTRIBUTION;
        for (uint256 i = 0; i < numberOfContributions; i++) {
            address contributor = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            );
            vm.deal(contributor, contributionAmount);
            vm.prank(contributor);
            tokenSale.contribute{value: contributionAmount}();
        }
        // Act & Assert: Exceeding the PRESALE_CAP should fail
        address lastContributor = address(
            uint160(uint256(keccak256(abi.encodePacked(numberOfContributions))))
        );
        vm.deal(lastContributor, contributionAmount);
        vm.expectRevert(bytes("ContributionExceedsCap()"));
        vm.prank(lastContributor);
        tokenSale.contribute{value: contributionAmount}();
    }

    function testDistributeTokensValid() public {
        uint256 amount = 1000; // Example amount
        address recipient = address(this);
        tokenSale.distributeTokens(recipient, amount);
        // Add assertions to check if the tokens were distributed successfully
    }

    function testFailDistributeTokensToZeroAddress() public {
        uint256 amount = 1000; // Example amount
        address recipient = address(0);
        vm.expectRevert(bytes("InvalidAddress()"));
        tokenSale.distributeTokens(recipient, amount);
    }

    function testFailEndPresaleWhenAlreadyEnded() public {
        tokenSale.endPresale(); // End presale first
        vm.expectRevert(bytes("PresaleAlreadyEnded()"));
        tokenSale.endPresale(); // Attempt to end presale again
    }

    function testFailClaimRefundWhenNotAvailable() public {
        vm.expectRevert(bytes("RefundNotAvailable()"));
        tokenSale.claimRefund();
    }

    function testIsPresaleActive() public {
        bool presaleActive = tokenSale._isPresaleActive();
        assertTrue(presaleActive, "Presale should be active");
        tokenSale.endPresale();
        presaleActive = tokenSale._isPresaleActive();
        assertFalse(presaleActive, "Presale should not be active");
    }
}
