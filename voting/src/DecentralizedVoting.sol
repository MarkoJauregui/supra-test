// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Decentralized Voting System
/// @author Marko Jauregui
/// @notice Implements a simple decentralized voting system
/// @dev Extends OpenZeppelin's Ownable for ownership management
contract DecentralizedVoting is Ownable {
    // Custom errors
    error DecentralizedVoting__AlreadyVoted();
    error DecentralizedVoting__NotRegistered();
    error DecentralizedVoting__InvalidCandidate();
    error DecentralizedVoting__AlreadyRegistered();

    // Structs
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint candidateId;
    }

    struct Candidate {
        string name;
        uint voteCount;
    }

    // State variables
    mapping(address => Voter) private s_voters;
    Candidate[] private s_candidates;

    // Events
    event VoterRegistered(address voter);
    event CandidateAdded(string candidateName);
    event VoteCasted(address voter, uint candidateId);

    /// @notice Constructor to initialize the contract with the initial owner
    /// @param initialOwner The address of the initial owner
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Registers the sender as a voter
    /// @dev Reverts if the sender is already registered
    function registerVoter() public {
        Voter storage voter = s_voters[msg.sender];

        if (voter.isRegistered) {
            revert DecentralizedVoting__AlreadyRegistered();
        }

        s_voters[msg.sender] = Voter(true, false, 0);
        emit VoterRegistered(msg.sender);
    }

    /// @notice Adds a new candidate to the election
    /// @dev Only callable by the contract owner
    /// @param _name The name of the candidate to add
    function addCandidate(string memory _name) public onlyOwner {
        s_candidates.push(Candidate(_name, 0));
        emit CandidateAdded(_name);
    }

    /// @notice Allows a registered voter to vote for a candidate
    /// @dev Reverts if the voter has already voted or if the candidate is invalid
    /// @param _candidateId The ID of the candidate to vote for
    function vote(uint _candidateId) public {
        Voter storage voter = s_voters[msg.sender];

        if (voter.hasVoted) {
            revert DecentralizedVoting__AlreadyVoted();
        }

        if (_candidateId >= s_candidates.length) {
            revert DecentralizedVoting__InvalidCandidate();
        }

        voter.hasVoted = true;
        voter.candidateId = _candidateId;

        s_candidates[_candidateId].voteCount += 1;

        emit VoteCasted(msg.sender, _candidateId);
    }

    /// @notice Retrieves the vote count for a specified candidate
    /// @dev Reverts if the candidate ID is invalid
    /// @param _candidateId The ID of the candidate
    /// @return The number of votes the candidate has received
    function getCandidateVoteCount(
        uint _candidateId
    ) public view returns (uint) {
        if (_candidateId >= s_candidates.length) {
            revert DecentralizedVoting__InvalidCandidate();
        }
        return s_candidates[_candidateId].voteCount;
    }
}
