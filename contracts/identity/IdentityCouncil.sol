pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Initializable.sol";
import "openzeppelin-zos/contracts/math/SafeMath.sol";

contract IdentityCouncil is Initializable {
    struct Proposal {
        address candidate;
        uint voteCount;

        // true for add, false for remove
        bool voteType;
    }

    mapping (address => uint) public councilIndex;    
    mapping (address => uint) public councilMemberWeight;
    mapping (address => mapping (uint => bool)) public votedOnProposal;

    // Proposal candidates are indicated by numeric values
    // The motivation for this is to prevent candidates who
    // aren't council members from being removed and to prevent
    // council members from being added redundantly.
    // 1 -> voteType = addition
    // 2 -> voteType = removal
    mapping (address => uint) public proposalCandidates;
    
    
    address[] council;
    Proposal[] proposals;

    // Amount of money to deposit when adding a new proposal
    uint256 public sybilResistantThresholdValue;

    // Percentage of council's votes needed to add new council member
    uint256 public quorumThreshold;

    event CouncilSetup(uint256 sybilResistantThresholdValue, uint256 quorumThreshold, address[] council);
    event CouncilMemberAdded(address member, uint count);
    event CouncilMemberRemoved(address member, uint count);
    event ProposalCreated(address candidate, uint proposalIndex, uint payment);
    event ProposalVotedOn(address candidate, uint voteCount, bool voteType);
    event Value(uint one, uint two);
    event LogProposal(address candidate, uint voteCount, bool voteType);

    function initialize(uint256 sybilAmt, uint256 quorumPt, address[] trusted) isInitializer public {
        require ( quorumPt > 0 && quorumPt <= 100);

        sybilResistantThresholdValue = sybilAmt;
        quorumThreshold = quorumPt;

        proposals.length++;
        council.length++;
        add(msg.sender);

        if (trusted.length > 0) {
            for (uint i = 0; i < trusted.length; i++) {
                add(trusted[i]);
            }
        }

        emit CouncilSetup(sybilResistantThresholdValue, quorumThreshold, getCouncil());
    }

    function vote(uint proposalIndex) isCouncilMember public {
        require( proposalIndex != 0 );
        require( proposals.length - 1 >= proposalIndex );

        address sender = council[councilIndex[msg.sender]];
        require( !votedOnProposal[sender][proposalIndex] );

        Proposal memory p = proposals[proposalIndex];

        // Assert the proposal has not been deleted at this index
        // so that completed proposals do not receive votes after
        require( p.candidate != address(0x0) );

        p.voteCount += councilMemberWeight[sender];
        votedOnProposal[sender][proposalIndex] = true;

        if (isVoteSuccess(p.voteCount)) {
            if (p.voteType) {
                add(p.candidate);                
            } else {
                remove(p.candidate);
            }

            delete proposals[proposalIndex];
            delete proposalCandidates[p.candidate];
        }

        emit ProposalVotedOn(p.candidate, p.voteCount, p.voteType);
    }

    function add(address candidate) internal {
        require( candidate != address(0x0) );

        // If candidate is already council member, do nothing
        if (councilIndex[candidate] > 0) {
            return;
        }

        uint index = council.length++;
        councilIndex[candidate] = index;
        council[index] = candidate;
        councilMemberWeight[candidate] = 1;

        emit CouncilMemberAdded(candidate, getCouncilSize());
    }

    function remove(address candidate) internal {
        uint index = councilIndex[candidate];
        delete council[index];
        delete councilIndex[candidate];

        resizeCouncilArray(index);
        emit CouncilMemberRemoved(candidate, getCouncilSize());
    }

    function propose(address candidate, bool voteType) payable public {
        require( candidate != address(0x0) );
        require( msg.value >= sybilResistantThresholdValue );

        if (voteType) {
            // A proposal to add a candidate should fail if the candidate is in the council
            require( councilIndex[candidate] == 0 );

            // There should not exist an open proposal to add or remove a candidate
            require( proposalCandidates[candidate] == 0 );
        } else {
            // A proposal to remove a candidate should fail if the candidate is not in the council
            require( councilIndex[candidate] > 0 );

            // There should not exist an open proposal to add or remove a candidate
            require( proposalCandidates[candidate] == 0 );
        }

        proposals.push(Proposal({
            candidate: candidate,
            voteType: voteType,
            voteCount: 0
        }));

        // TODO: Remove this and supplemental logic if possible
        proposalCandidates[candidate] = (voteType) ? 1 : 2;

        emit ProposalCreated(candidate, proposals.length - 1, msg.value);

        uint leftover = msg.value - sybilResistantThresholdValue;
        msg.sender.transfer(leftover);
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
