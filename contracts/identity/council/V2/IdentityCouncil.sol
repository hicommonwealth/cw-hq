pragma solidity ^0.4.24;

import "zos-lib/contracts/migrations/Initializable.sol";
import "./ProposalManager.sol";

contract IdentityCouncil is Initializable {
    ProposalManager manager;

    mapping (address => uint) public councilIndex;    
    mapping (address => uint) public councilMemberWeight;

    // Council address identities, targetting ERC725 identity contracts
    address[] council;

    // Amount of money to deposit when adding a new proposal
    uint256 public sybilThresholdValue;

    // Percentage of council's votes needed to add new council member
    uint256 public quorumThreshold;

    event CouncilSetup(uint256 sybilResistantThresholdValue, uint256 quorumThreshold, address[] council);
    event CouncilMemberAdded(address member, uint count);
    event CouncilMemberRemoved(address member, uint count);

    function initialize(
        address _proposalManagerAddress,
        uint256 _sybilThresholdValue,
        uint256 _quorumThreshold,
        address[] _council
    )
        isInitializer
        public 
    {

    }

    function add() isProposalManager public returns (bool) {

    }

    function remove() isProposalManager public returns (bool) {

    }

    function execute() isProposalManager {

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
    
    modifier isProposalManager() { 
        require (msg.sender == address(manager)); 
        _; 
    }
    
}
