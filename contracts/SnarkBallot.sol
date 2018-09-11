pragma solidity ^0.4.22;

import './MerkleTree.sol';
import './Verified.sol';
import './SnarkUtil.sol';

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
    function reveal(bytes32 vote) isCommit(commitAndReveal) returns (bool);
    function votePrice(uint amount) constant returns (uint);
    function isRoot(bytes32 root) constant returns(bool);
    function nullifierToAddress(bytes32 source) returns(address);
}