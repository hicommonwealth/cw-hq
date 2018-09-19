/*    
    copyright 2018 to the Commonwealth-HQ Authors

    This file is part of Commonwealth-HQ.

    Commonwealth-HQ is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Commonwealth-HQ is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Commonwealth-HQ.  If not, see <https://www.gnu.org/licenses/>.
*/

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

    function voteOnCandidateProposal(uint proposalIndex) isCouncilMember public {
        require( proposalIndex != 0 );
        require( candidateProposals.length - 1 >= proposalIndex );

        address sender = council[councilIndex[msg.sender]];
        require( !votedOnCandidateProposal[sender][proposalIndex] );

        CandidateProposal memory p = candidateProposals[proposalIndex];

        // Assert the proposal has not been deleted at this index
        // so that completed candidateProposals do not receive votes after
        require( p.candidate != address(0x0) );

        p.voteCount += councilMemberWeight[sender];
        votedOnCandidateProposal[sender][proposalIndex] = true;

        if (isVoteSuccess(p.voteCount)) {
            if (p.voteType) {
                addCouncilMember(p.candidate);                
            } else {
                removeCouncilMember(p.candidate);
            }

            delete candidateProposals[proposalIndex];
            delete candidateProposalExists[p.candidate];
        }

        emit CandidateProposalVotedOn(p.candidate, p.voteCount, p.voteType);
    }

    function addCouncilMember(address candidate) internal {
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

    function removeCouncilMember(address candidate) internal {
        uint index = councilIndex[candidate];
        delete council[index];
        delete councilIndex[candidate];

        resizeCouncilArray(index);
        emit CouncilMemberRemoved(candidate, getCouncilSize());
    }

    function proposeCandidate(address candidate, bool voteType) payable public {
        require( candidate != address(0x0) );

        // A proposal must pay the sybil fee
        require( msg.value >= sybilResistantThresholdValue );

        // There should not exist an open proposal to add or remove a candidate
        require( !candidateProposalExists[candidate] );

        // A proposal to add (remove) a candidate should 
        // fail if the candidate is in (not in) the council 
        require( (voteType)
            ? (councilIndex[candidate] == 0) 
            : councilIndex[candidate] > 0
        );

        candidateProposals.push(CandidateProposal({
            candidate: candidate,
            voteType: voteType,
            voteCount: 0
        }));


        emit CandidateProposalCreated(candidate, candidateProposals.length - 1, msg.value);
        candidateProposalExists[candidate] = true;

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
