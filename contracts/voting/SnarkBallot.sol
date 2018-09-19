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

pragma solidity ^0.4.22;

import '../crypto/MerkleTree.sol';
import '../crypto/Verifier.sol';

contract SnarkBallot is MerkleTree {
    Verifier public zksnark_verify;

    mapping (bytes32 => bool) roots;
    mapping (bytes32 => bytes32) nullifierVotes;
    bool public commitAndReveal;

    event Vote(address); 

    function deposit (bytes32 leaf) payable;
    function vote (
        uint[2] a,
        uint[2] a_p,
        uint[2][2] b,
        uint[2] b_p,
        uint[2] c,
        uint[2] c_p,
        uint[2] h,
        uint[2] k,
        uint[] input,
        bytes32 commitment
    ) returns (address);
    function reveal(bytes32 vote) returns (bool);
    function votePrice(uint amount) constant returns (uint);
    function isRoot(bytes32 root) constant returns(bool);
    function nullifierToAddress(bytes32 source) returns(address);
    function merge253bitWords(uint left, uint right) returns(bytes32);
    function pad3bit(uint input) constant returns(uint);
    function getZero(bytes32 x) returns(bytes32);
    function padZero(bytes32 x) returns(bytes32);
    function reverseByte(uint a) public pure returns (uint);
    function reverse(bytes32 a) public pure returns(bytes32);
}