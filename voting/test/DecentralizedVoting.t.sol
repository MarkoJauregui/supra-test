// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/DecentralizedVoting.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DecentralizedVotingTest is Test {
    DecentralizedVoting voting;

    function setUp() public {
        voting = new DecentralizedVoting(address(this));
    }

    function testDeployment() public view {
        assert(address(voting) != address(0));
    }

    function testAddCandidate() public {
        string memory candidateName = "Candidate 1";
        voting.addCandidate(candidateName);
        // Add assertions to verify candidate addition
    }

    function testFailRegisterVoterTwice() public {
        voting.registerVoter();
        voting.registerVoter(); // This should fail
    }

    function testVote() public {
        string memory candidateName = "Candidate 1";
        voting.addCandidate(candidateName);
        voting.registerVoter();
        voting.vote(0);
        // Add assertions to verify the vote
    }

    function testFailDoubleVoting() public {
        string memory candidateName = "Candidate 1";
        voting.addCandidate(candidateName);
        voting.registerVoter();
        voting.vote(0);
        voting.vote(0); // This should fail
    }

    function testFailAddCandidateByNonOwner() public {
        vm.prank(address(0x123)); // Forge specific: impersonate another user
        string memory candidateName = "Candidate 2";
        voting.addCandidate(candidateName); // This should fail
    }

    function testFailVoteInvalidCandidate() public {
        voting.registerVoter();
        voting.vote(999); // Invalid candidate ID, should fail
    }

    function testVoteCount() public {
        string memory candidateName = "Candidate 1";
        voting.addCandidate(candidateName);
        voting.registerVoter();
        voting.vote(0);

        uint voteCount = voting.getCandidateVoteCount(0);
        assertEq(voteCount, 1); // Check if the vote count is 1
    }

    function testFailVoteUnregisteredVoter() public {
        vm.prank(address(0x123)); // Use a different address
        voting.vote(0); // This should fail as the voter is not registered
    }

    function testFailGetVoteCountInvalidCandidate() public view {
        uint invalidCandidateId = 999;
        voting.getCandidateVoteCount(invalidCandidateId); // Should fail
    }

    function testGetVoteCountValidCandidate() public {
        string memory candidateName = "Candidate 1";
        voting.addCandidate(candidateName);
        voting.registerVoter();
        voting.vote(0);

        uint voteCount = voting.getCandidateVoteCount(0);
        assertEq(voteCount, 1);
    }
}
