pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Initializable.sol";
import "openzeppelin-zos/contracts/math/SafeMath.sol";

contract IdentityCouncil is Initializable {

    struct Voter {
        uint weight;
        mapping (uint => bool) votedProposals;
    }

    struct Proposal {
        address candidate;
        uint voteCount;

        // true for add, false for remove
        bool voteType;
    }

    mapping (address => uint) councilIndex;    
    
    Voter[] council;
    Proposal[] proposals;

    // Amount of money to deposit when adding a new proposal
    uint256 sybilResistantThresholdValue;

    // Percentage of council's votes needed to add new council member
    uint256 quorumThreshold;

    function initialize(
        uint256 sybilResistantThresholdValue,
        uint256 quorumThreshold,
        address[] trustedIdentities
    ) 
        isInitializer public 
    {
        proposals.length++;
        council.length++;
        add(msg.sender);

        if (trustedIdentities.length > 0) {
            for (uint i = 0; i < trustedIdentities.length; i++) {
                // Index identities one slot above 0th position
                address identity = trustedIdentities[i];
                add(identity);
            }
        }
    }

    function vote(uint proposal) isCouncilMember public returns (bool) {
        Voter sender = council[councilIndex[msg.sender]];
        if (sender.votedProposals[proposal])
            return false;

        proposals[proposal].voteCount += sender.weight;
        sender.votedProposals[proposal] = true;

        if (isVoteSuccess(proposal)) {
            if (proposals[proposal].voteType) {
                add(proposals[proposal].candidate);                
            } else {
                remove(proposals[proposal].candidate);
            }

            delete proposals[proposal];
        }

        return true;
    }

    function add(address candidate) internal {
        uint index = council.length++;
        councilIndex[candidate] = index;
        council[index] = Voter({
            weight: 1
        });
    }

    function remove(address candidate) internal {
        uint index = councilIndex[candidate];
        delete council[index];
        delete councilIndex[candidate];
    }

    function propose(address candidate, bool voteType) payable returns (uint) {
        require( msg.value >= sybilResistantThresholdValue );

        proposals.push(Proposal({
            candidate: candidate,
            voteType: voteType,
            voteCount: 0
        }));

        return proposals.length - 1;
    }

    function isVoteSuccess(uint proposal) constant returns (bool) {
        uint count = proposals[proposal].voteCount;

        // Calculate fraction of votes = votecount / council.length
        uint frac = SafeMath.div(SafeMath.mul(1 ether, count), council.length);

        // Calculate quorum threshold = quorumThreshold / 100
        uint thresh = SafeMath.div(SafeMath.mul(1 ether, quorumThreshold), 100);

        // Check if fraction of votes is larger than quorum threshold
        return frac >= thresh;
    }

    modifier isCouncilMember() { 
        require( councilIndex[msg.sender] > 0 ); 
        _; 
    }
    
}
