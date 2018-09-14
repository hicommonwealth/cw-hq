pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Initializable.sol";
import "openzeppelin-zos/contracts/math/SafeMath.sol";
import "./IdentityCouncil.sol";

contract ProposalManager is Initializable {
    IdentityCouncil IC;

    bytes32 constant CANDIDATE_PREFIX   = "CANDIDATE";
    bytes32 constant ACTION_PREFIX      = "ACTION";

    struct CandidateProposal {
        address candidate;
        uint voteCount;
        bool voteType; // true for add, false for remove
    }

    struct ActionProposal {
        address to;
        bytes data;
        uint value;
        uint voteCount;
    }

    mapping (bytes32 => CandidateProposal) candidateProposals;
    mapping (bytes32 => ActionProposal) actionProposals;

    mapping (address => mapping (bytes32 => bool)) public votedOnProposal;
    mapping (bytes32 => bool) public proposalExists;

    event CandidateProposalCreated(address candidate, bytes32 proposalKey);
    event CandidateProposalVotedOn(address candidate, bytes32 proposalKey);

    event ActionProposalCreated(address sender, bytes32 proposalKey);
    event ActionProposalVotedOn(address sender, bytes32 proposalKey);

    function initialize(address _identityCouncilAddress) isInitializer public {
        IC = IdentityCouncil(_identityCouncil);
    }

    function proposeCandidate(address _candidate, bool _voteType) public {
        require( _candidate != address(0x0) );
    }

    function proposeAction(address _to, bytes _data, uint _value) public {
        require( _to != address(0x0) );
    }

    function vote(uint8 _proposalType, bytes32 _proposalKey) isCouncilMember public {
        require( _proposalKey != bytes32(0x0) );
        require( !votedOnProposal[msg.sender][_proposalKey] );

        bool success;
        if (_proposalType == 0) {
            require( candidateProposals[_proposalKey].candidate != address(0x0) );
            success = voteOnCandidate(_proposalKey);
        } else if (_proposalType == 1) {
            require( actionProposals[_proposalKey].to != address(0x0) );
            success = voteOnAction(_proposalKey);
        } else {
            throw;
        }

        require( success );
        votedOnProposal[msg.sender] = true;
    }

    function voteOnCandidate(bytes32 _proposalKey) internal returns (bool) {
        require( !votedOnProposal[msg.sender][proposalIndex] );

        CandidateProposal memory p = candidateProposals[_proposalKey];

        p.voteCount += councilMemberWeight[sender];

        if (isVoteSuccess(p.voteCount)) {
            bool success = (p.voteType)
                ? council.add(p.candidate)
                : council.remove(p.candidate);

            require( success );

            delete candidateProposals[proposalIndex];
            delete candidateProposalExists[p.candidate];
        }

        emit CandidateProposalVotedOn(p.candidate, p.voteCount, p.voteType);
    }
    
    function isVoteSuccess(uint count) internal constant returns (bool) {
        // Calculate fraction of votes = voteCount / council.length
        uint frac = SafeMath.div(SafeMath.mul(1 ether, count), council.getCouncilSize());

        // Calculate quorum threshold = quorumThreshold / 100
        uint thresh = SafeMath.div(SafeMath.mul(1 ether, council.quorumThreshold), 100);

        // Check if fraction of votes is larger than quorum threshold
        return frac >= thresh;
    }

    modifier isCouncilMember() { 
        require (council.councilIndex[msg.sender] > 0); 
        _; 
    }
}