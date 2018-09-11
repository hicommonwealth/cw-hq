pragma solidity ^0.4.22;

import './ERC725.sol';
import './ERC735.sol';

contract KeyHolder is ERC725, ERC735 {

    uint256 executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    mapping (bytes32 => Key) keys;
    mapping (uint256 => bytes32[]) keysByPurpose;
    mapping (uint256 => Execution) executions;

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    function removeKey(bytes32 _key) public returns (bool success);
    function keyHasPurpose(bytes32 _key, uint256 _purpose) public view returns(bool result);
}