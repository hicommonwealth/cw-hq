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
import "./ProposalManager.sol";

contract IdentityCouncil is Initializable {
    ProposalManager PM;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    uint256 executionNonce;
    mapping (uint256 => Execution) executions;

    mapping (address => uint) public councilIndex;    
    mapping (address => uint) public councilMemberWeight;
    mapping (address => uint) public issuersIndex;    
    mapping (address => uint) public issuersWeight;

    // Council address identities, targeting ERC725 identity contracts
    address[] council;

    // Claims issuer identities, targeting ERC725 identity contracts
    address[] issuers;

    // Amount of money to deposit when adding a new proposal
    // Parameter type 1
    uint256 public sybilThresholdValue;

    // Percentage of council's votes needed to add new council member
    // Parameter type 2
    uint256 public candidateQuorumThreshold;

    // Percentage of council's votes needed to add new claims issuer
    // Parameter type 3
    uint256 public issuersQuorumThreshold;

    // Percentage of council's votes needed to execute a new execution
    // Parameter type 4
    uint256 public executionQuorumThreshold;

    event CouncilSetup(
        uint256 sybilResistantThresholdValue,
        uint256[] indexed quorumthresholds,
        address[] indexed council,
        address[] indexed issuers);

    event CouncilMemberAdded(
        address indexed candidate,
        uint indexed count);
    event CouncilMemberRemoved(
        address indexed candidate,
        uint indexed count);

    event IssuerAdded(
        address indexed candidate,
        uint indexed count);
    event IssuerRemoved(
        address indexed candidate,
        uint indexed count);

    event Executed(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data);
    event ExecutionFailed(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data);

    function initialize(
        address _proposalManagerAddress,
        uint256 _sybilThresholdValue,
        uint256 _candidateQuorumThreshold,
        uint256 _issuersQuorumThreshold,
        uint256 _executionQuorumThreshold,
        address[] _council,
        address[] _issuers
    )
        isInitializer
        public 
    {
        require ( _candidateQuorumThreshold > 0 && _candidateQuorumThreshold <= 100);
        require ( _issuersQuorumThreshold > 0 && _issuersQuorumThreshold <= 100);
        require ( _executionQuorumThreshold > 0 && _executionQuorumThreshold <= 100);

        sybilResistantThresholdValue = _sybilThresholdValue;
        candidateQuorumThreshold = _candidateQuorumThreshold;
        issuersQuorumThreshold = _issuersQuorumThreshold;
        executionQuorumThreshold = _executionQuorumThreshold;
        PM = ProposalManager(_proposalManagerAddress);
        
        council.length++;
        issuers.length++;

        // Add council members
        add(msg.sender, 1);
        for (uint i = 0; i < _council.length; i++) {
            add(_council[i], 1);
        }

        // Add claims issuers
        add(msg.sender, 2);
        for (uint i = 0; i < _issuers.length; i++) {
            add(_issuers[i], 2);
        }

        emit CouncilSetup(
            sybilResistantThresholdValue,
            [candidateQuorumThreshold, issuersQuorumThreshold, executionQuorumThreshold],
            council,
            issuers);
    }

    function add(
        uint8 _candidateType,
        address _candidate
    )
        isInitialized
        isProposalManager
        public
        returns (bool)
    {
        require( _candidate != address(0x0) );

        // Council member addition
        if (_candidateType == 1) {
            uint index = council.length++;
            councilIndex[_candidate] = index;
            council[index] = _candidate;
            councilMemberWeight[_candidate] = 1;

            emit CouncilMemberAdded(
                _candidate,
                (council.length > 0) ? council.length - 1 : 0);

        // Claims issuer addition
        } else if (_candidateType == 2) {
            uint index = issuers.length++;
            issuersIndex[_candidate] = index;
            issuers[index] = _candidate;
            issuersWeight[_candidate] = 1;

            emit IssuerAdded(
                _candidate,
                (issuers.length > 0) ? issuers.length - 1 : 0);
        } else {
            throw;
        }
    }

    function remove(
        uint8 _candidateType,
        address _candidate
    )
        isInitialized
        isProposalManager
        public
        returns (bool)
    {
        require( _candidate != address(0x0) );

        // Council member removal
        if (_candidateType == 1) {
            uint index = councilIndex[_candidate];
            delete councilIndex[_candidate];
            council = resizeArray(index, council);

            emit CouncilMemberRemoved(
                _candidate,
                (council.length > 0) ? council.length - 1 : 0);

        // Claims issuer removal
        } else if (_candidateType == 2) {
            uint index = issuersIndex[_candidate];
            delete issuersIndex[_candidate];
            issuers = resizeArray(index, issuers);

            emit IssuerRemoved(
                _candidate,
                (issuers.length > 0) ? issuers.length - 1 : 0);
        } else {
            throw;
        }
    }

    function update(
        uint8 _parameterType,
    )
        returns
    {
        if (_paramterType == 1) {
            quorumThreshold = IC.sybilThresholdValue;
        } else if (_paramterType == 2) {
            quorumThreshold = IC.candidateQuorumThreshold;
        } else if (_paramterType == 3) {
            quorumThreshold = IC.issuersQuorumThreshold;
        } else if (_paramterType == 4) {
            quorumThreshold = IC.executionQuorumThreshold
        } else {
            throw;
        }
    }
    

    // TODO: Check if this logic is sound. We want to allow
    //       a new execution to take place from the ProposalManager
    function execute(
        address _to,
        bytes _data,
        uint _value
    )
        isInitialized
        isProposalManager
        public
        returns (bool)
    {
        require( executions[executionNonce].to == address(0x0) );

        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        success = executions[executionNonce].to.call(executions[executionNonce].data, 0);
        if (success) {
            executions[executionNonce].executed = true;
            emit Executed(
                executionNonce,
                executions[executionNonce].to,
                executions[executionNonce].value,
                executions[executionNonce].data);
        } else {
            emit ExecutionFailed(
                executionNonce,
                executions[executionNonce].to,
                executions[executionNonce].value,
                executions[executionNonce].data
            );
        }

        executionNonce++;
    }

    // TODO: Check if this logic is sound. We want to allow
    //       any approved execution to be re-executed by anyone.
    function reExecute(
        uint256 _id
    )
        isInitialized
        public
    {
        require( !executions[_id].executed );
        success = executions[_id].to.call(executions[_id].data, 0);
        if (success) {
            executions[_id].executed = true;
            emit Executed(
                _id,
                executions[_id].to,
                executions[_id].value,
                executions[_id].data);
        } else {
            emit ExecutionFailed(
                _id,
                executions[_id].to,
                executions[_id].value,
                executions[_id].data
            );
        }

        executionNonce++;
        return success;
    }

    function resizeArray(
        uint index,
        address[] _array
    )
        internal
        constant
        returns (address[]);
    {
        address[] memory arrayNew = new address[](length - 1);
        for (uint i = 0; i < arrayNew.length; i++){
            if (i != index && i < index){
                arrayNew[i] = _array[i];
            } else {
                arrayNew[i] = _array[i + 1];
            }
        }

        return arrayNew;
    }

    function getQuorumThreshold(
        uint _parameterType
    )
        public
        constant
        returns (uint)
    {
        if (_paramterType == 1) {
            quorumThreshold = IC.sybilThresholdValue;
        } else if (_paramterType == 2) {
            quorumThreshold = IC.candidateQuorumThreshold;
        } else if (_paramterType == 3) {
            quorumThreshold = IC.issuersQuorumThreshold;
        } else if (_paramterType == 4) {
            quorumThreshold = IC.executionQuorumThreshold
        } else {
            throw;
        }
    }
    
    modifier isProposalManager() { 
        require (msg.sender == address(manager)); 
        _; 
    }

    modifier isInitialized() { 
        require (initialized); 
        _; 
    }
}
