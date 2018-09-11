pragma solidity ^0.4.22;

library SnarkUtil {
    function merge253bitWords(uint left, uint right) returns(bytes32);
    function pad3bit(uint input) constant returns(uint);
    function getZero(bytes32 x) returns(bytes32);
    function padZero(bytes32 x) returns(bytes32);
    function reverseByte(uint a) public pure returns (uint);
    function reverse(bytes32 a) public pure returns(bytes32);
}