pragma solidity^0.4.22;

contract MerkelTree {
    mapping (bytes32 => bool) public serials;
    mapping (bytes32 => bool) public roots;
    uint public tree_depth = 29;
    uint public no_leaves = 536870912;
    
    struct Mtree {
        uint cur;
        bytes32[536870912][30] leaves2;
    }

    Mtree public MT;

    event LeafAdded(uint index);

    function insert(bytes32 com) internal returns (bool res);
    function getMerkelProof(uint index) constant returns (bytes32[29], uint[29]);
    function getSha256(bytes32 input, bytes32 sk) constant returns (bytes32);
    function getUniqueLeaf(bytes32 leaf, uint depth) returns (bytes32);
    function updateTree() internal returns(bytes32 root);
    function getLeaf(uint j,uint k) constant returns (bytes32 root);
    function getRoot() constant returns(bytes32 root);
}