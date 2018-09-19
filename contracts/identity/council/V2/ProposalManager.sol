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
import "./IdentityCouncil.sol";

contract ProposalManager is Initializable {
    IdentityCouncil IC;

    bytes32 constant CANDIDATE_PREFIX   = "CANDIDATE";
    bytes32 constant EXECUTION_PREFIX   = "EXECUTION";

    struct CandidateProposal {
        address candidate;
        uint voteCount;
        bool voteType; // true for add, false for remove
    }

    struct ExecutionProposal {
        address to;
        bytes data;
        uint value;
        uint voteCount;
    }

    mapping (bytes32 => CandidateProposal) candidateProposals;
    mapping (bytes32 => ExecutionProposal) executionProposals;

    mapping (address => mapping (bytes32 => bool)) public votedOnProposal;
    mapping (bytes32 => bool) public proposalExists;

    event ProposalManagerSetup(address identityCouncil);

    event CandidateProposalCreated(
        address candidate,
        bytes32 proposalKey);
    event CandidateProposalVotedOn(
        address candidate,
        bytes32 proposalKey);

    event ExecutionProposalCreated(
        address indexed to,
        bytes data,
        uint indexed value,
        bytes32 indexed proposalKey);
    event ExecutionProposalVotedOn(
        address indexed to,
        bytes data,
        uint indexed value,
        bytes32 indexed proposalKey);

    function initialize(address _identityCouncilAddress) isInitializer public {
        IC = IdentityCouncil(_identityCouncil);
    }

    function proposeCandidate(
        address _candidate,
        bool _voteType
    )
        isInitialized
        public
    {
        require( _candidate != address(0x0) );

        bytes32 _key = keccak256(abi.encodePacked(CANDIDATE_PREFIX, _candidate));
        require( !proposalExists[_key] );
        proposalExists[_key] = true;

        candidateProposals[_key] = CandidateProposal({
            candidate: _candidate,
            voteCount: (IC.councilIndex[msg.sender] > 0) ? 1 : 0,
            voteType: _voteType
        });

        votedOnProposal[msg.sender][_key] = true;
    }

    function proposeExecution(
        address _to,
        bytes _data,
        uint _value
    )
        isCouncilMember
        isInitialized
        public
    {
        require( _to != address(0x0) );
        require( _data != bytes(0x0) );

        bytes32 _key = keccak256(abi.encodePacked(EXECUTION_PREFIX, _to, _data, _value));
        require( !proposalExists[_key] );
        proposalExists[_key] = true;

        executionProposals[_key] = ExecutionProposal({
            to: _to,
            data: _data,
            value: _value,
            voteCount: 1,
            approved: false
        });

        votedOnProposal[msg.sender][_key] = true;
    }

    function vote(
        uint8 _parameterType,
        bytes32 _proposalKey
    )
        isCouncilMember
        isInitialized
        public
    {
        require( _proposalKey != bytes32(0x0) );
        require( proposalExists[_proposalKey] );
        require( !votedOnProposal[msg.sender][_proposalKey] );

        if (_parameterType == 2) {
            require( candidateProposals[_proposalKey].candidate != address(0x0) );
            success = voteOnCandidate(_proposalKey, msg.sender);
        } else if (_parameterType == 4) {
            require( actionProposals[_proposalKey].to != address(0x0) );
            success = voteOnExecution(_proposalKey, msg.sender);
        } else {
            throw;
        }

        votedOnProposal[msg.sender] = true;
    }

    function voteOnCandidate(
        bytes32 _proposalKey,
        address sender
    )
        internal
    {
        CandidateProposal memory p = candidateProposals[_proposalKey];

        p.voteCount += councilMemberWeight[sender];

        if (isVoteSuccess(p.voteCount, 2)) {
            bool success = (p.voteType)
                ? IC.add(p.candidate)
                : IC.remove(p.candidate);

            require( success );

            delete candidateProposals[_proposalKey];
            delete candidateProposalExists[p.candidate];
        }

        emit CandidateProposalVotedOn(p.candidate, p.voteCount, p.voteType);
    }

    function voteOnExecution(
        bytes32 _proposalKey,
        address sender
    )
        internal
    {
        ExecutionProposal memory p = executionProposals[_proposalKey];

        p.voteCount += councilMemberWeight[sender];

        if (isVoteSuccess(p.voteCount, 4)) {
            IC.execute(p.to, p.data, p.value);

            delete executionProposals[_proposalKey];
            delete executionProposalExists[p.candidate];
        }

        emit ExecutionProposalVotedOn(p.candidate, p.voteCount, p.voteType);
    }
    
    function isVoteSuccess(
        uint _count,
        uint8 _parameterType
    )
        internal
        constant
        returns (bool)
    {
        uint8 quorumThreshold = IC.getQuorumThreshold(_parameterType);

        // Calculate fraction of votes = voteCount / council.length
        uint frac = SafeMath.div(SafeMath.mul(1 ether, _count), IC.getCouncilSize());

        // Calculate quorum threshold = quorumThreshold / 100
        uint thresh = SafeMath.div(SafeMath.mul(1 ether, quorumThreshold), 100);

        // Check if fraction of votes is larger than quorum threshold
        return frac >= thresh;
    }

    modifier isCouncilMember() { 
        require (IC.councilIndex[msg.sender] > 0); 
        _; 
    }

    modifier isInitialized() { 
        require (initialized); 
        _; 
    }
}