pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Initializable.sol";
import "openzeppelin-zos/contracts/math/SafeMath.sol";

contract IdentityCouncil is Initializable {
    struct CandidateProposal {
        address candidate;
        uint voteCount;
        bool voteType; // true for add, false for remove
    }

    mapping (address => uint) public councilIndex;    
    mapping (address => uint) public councilMemberWeight;
    mapping (address => mapping (uint => bool)) public votedOnCandidateProposal;
    mapping (address => bool) public candidateProposalExists;
    
    address[] council;
    CandidateProposal[] candidateProposals;

    // Amount of money to deposit when adding a new proposal
    uint256 public sybilResistantThresholdValue;

    // Percentage of council's votes needed to add new council member
    uint256 public quorumThreshold;

    event CouncilSetup(uint256 sybilResistantThresholdValue, uint256 quorumThreshold, address[] council);
    event CouncilMemberAdded(address member, uint count);
    event CouncilMemberRemoved(address member, uint count);

    event CandidateProposalCreated(address candidate, uint proposalIndex, uint payment);
    event CandidateProposalVotedOn(address candidate, uint voteCount, bool voteType);

    function initialize(uint256 sybilAmt, uint256 quorumPt, address[] trusted) isInitializer public {
        require ( quorumPt > 0 && quorumPt <= 100);

        sybilResistantThresholdValue = sybilAmt;
        quorumThreshold = quorumPt;

        candidateProposals.length++;
        council.length++;
        addCouncilMember(msg.sender);

        if (trusted.length > 0) {
            for (uint i = 0; i < trusted.length; i++) {
                addCouncilMember(trusted[i]);
            }
        }

        emit CouncilSetup(sybilResistantThresholdValue, quorumThreshold, getCouncil());
    }

    function isVoteSuccess(uint count) internal constant returns (bool) {
        // Calculate fraction of votes = voteCount / council.length
        uint frac = SafeMath.div(SafeMath.mul(1 ether, count), getCouncilSize());

        // Calculate quorum threshold = quorumThreshold / 100
        uint thresh = SafeMath.div(SafeMath.mul(1 ether, quorumThreshold), 100);

        // Check if fraction of votes is larger than quorum threshold
        return frac >= thresh;
    }

    function resizeCouncilArray(uint index) internal {
        address[] memory arrayNew = new address[](council.length-1);
        for (uint i = 0; i<arrayNew.length; i++){
            if(i != index && i<index){
                arrayNew[i] = council[i];
            } else {
                arrayNew[i] = council[i+1];
            }
        }
        delete council;
        council = arrayNew;
    }

    function getCouncilSize() public constant returns (uint) {
        return (council.length == 0) ? 0 : council.length - 1;
    }

    function getCouncil() public constant returns (address[]) {
        address[] memory arrayNew = new address[](council.length-1);
        for (uint i = 1; i<council.length; i++){
            arrayNew[i-1] = council[i];
        }

        return arrayNew;
    }

    modifier isCouncilMember() { 
        require (councilIndex[msg.sender] > 0); 
        _; 
    }
    
}

contract ProposalManager {
    function contractName () {
        
    }    
}

