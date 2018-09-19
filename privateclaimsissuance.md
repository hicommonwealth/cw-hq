## Abstract

A previous paper of ours detailed the construction of an Identity Council

## Introduction

Why is identitiy important at all? - Fraud and (sybil attacks) prevention for voting, counterparty risk in finance protocols, KYC/AML for compliance.

What are primatives to use - anonymity. coercion resistance

What are challenges with identity
-> Privacy preservation for on-chain claims

Why is this important to Commonwealth? Nedd individuals to participate in governance at all.

How do we make it usable?

## Privacy Tools

Privacy is at the core of our ultimate goals. There are a variety of privacy enhancing tools already available on Ethereum, and we plan to take advantage of that as well as lead the dialogue for new tools. Currently, there are precompiled contracts for cryptographic primitives based upon elliptic curves. There are also utilities such as `ecrecover` that allow recovery of the signer's public key. These basic primitives allow us to develop privacy enhancing technology using:

1. Zero-knowledge proofs
2. Commitment schemes
3. Blinding cryptography
4. Ring signatures

While some of these tools are more readily available than others, with regards to the costs of gas in a technology's respective computation, we define the systems that are paramount to Commonwealth's Identity standard.

## Privacy System #1 - Anonymous voting

Voting is a key piece in a governing system, allowing stakeholders to signal their preference over proposed alternatives. Anonymous voting allows individuals to do so privately. Similarly, these protocols are based at a high level on being able to prove membership in a set, one in which encompasses the claims made by such an identity (ownership of X coins or member of an arbitrary organization). Our approach to anonymous voting is twofold.

1. Zero-knowledge proof and cryptographic accumulator based voting protocols.
2. Ring signature based voting protocols.

**Zero-knowledge Scheme**

The former, zero-knowledge based, system has at its core a cryptographic accumulator such as a merkle tree. Users incrementally build the tree by submitting a provable claim about their identities. On the other hand, cryptographic accumulators can be built up front by trusted third parties endowing claims upon identities in the respective membership set. Examples are as follows:

1. ***Incremental construction:*** Alice wants to prove that she owns 50 LPT to participate in a Livepeer election, which endows token holders votes based upon an arbitrary vote pricing rule (1 coin, 1 vote). She deposits 50 LPT into a contract that enforces depositors to send exactly 50 LPT and also sends a hash of secret data as a function parameter. This hash is added as a leaf in the merkle tree. Alice then generates a clean address, potentially using a derived stealth address based upon a hierarchically deterministic wallet, and submits a vote using a zero-knowledge proof that she knows the pre-image of a hash that is also a leaf in the merkle tree, using a merkle proof. Alice has successfully voted without linking her vote to her depositing address.

  *Note: the security of this scheme, assuming the hash function is secure, is entirely dependent on how many individuals have also deposited into the contract. That is, the size of the anonymity set determines the link-ability of votes in the system.*

2. ***Upfront construction:*** A trusted third party like Github wants to allow users to vote on proposed future projects and since they have a database of active users can build a merkle tree of all valid users up to some time ***t***. Github can, similar in the example above, take a secret, hash it with the username of the valid user's account or other identifying information, and use this data as leaves in the merkle tree. Upon sharing the secret with respective users in the Github web application, user's can participate in the vote just as Alice did, by submitting zero-knowledge proofs of knowledge of the pre-image of a leaf node's hash and a merkle path asserting the existence of the data.

**Ring Signature Scheme**

The latter approach based upon ring signatures works with a different set of design constraints. Building a ring signature based mixing service requires setting a variety of parameters such as the size of the ring as well as the time necessary to close the initialization and voting process. As the size of the anonymity set determines some degree of the link-ability of votes in the system, the larger the better. However, the larger the anonymity set, the longer it takes to potentially finish the initialization step where users submit their public keys into the ring. These parameters require more thought and pose challenges to designing efficient schemes. Moreover, we now describe how a ring signature based scheme works in the same fashion as before with additional insight into extensions with ERC725 and ERC735 standards.

- ***Incremental construction:*** Alice wants to host a vote over a set of issues, potentially undefined up to this point, and wants to ensure that the vote is both anonymous and that only certain identities — those than can prove a specific claim — can vote. Thus she designs a ring that requires users to submit these proofs, in the form of a claim issued on an ERC735 compliant identity, in order to gain admission into the ring. Alice defines the constraints that allow eligible additions to the ring, potentially delaying the length of time required to fill up the specified ring size. Nonetheless, when valid identities based upon these standards fill up the ring in its entirety, identities need only submit proofs of membership and votes to engage in the anonymous voting protocol with a ring signature. Using linkable ring signatures, the contract can enforce the that no single identity votes twice or incentivize users to handle such work using incentives and fraud proofs.
- ***Upfront construction:*** Github wants to allow all its current users to vote on a new change in their product. They create a ring signature voting protocol contract and populate the ring with all the identities of their users, assuming all Github users have an associated ERC725/ERC735 compliant identity contract to stand in their place. Users simply follow the scheme defined above now that the accumulator has already been constructed and submit linkable ring signatures to cast votes.

## Privacy System #2 - Anonymous credential issuance

Integral to any of the voting implementations described above is the notion of having claims to prove membership of a set of identities, whether through merkle trees or ring signatures sets. While some claims are easier to describe than others, requiring no trusted third party such as token ownership, there are countless use cases for having a claims issuance service for trusted third parties. This system encompasses the crux of combining the centralized and decentralized world to build heavily useful technology. Better yet, a system that enables the anonymous issuance of credentials allows individuals to participate in claims-worthy protocols without disclosing the fundamental information that makes up such claims.

Credentials, at their core, are groups of claims. Credentials allow individuals to prove they have the necessary information and permission to access a protected resource or make certain claims about themselves or aspects of a system in general, usually without disclosing that information. Users of popular social media websites can now use OAuth to obtain a temporary credential that ensures such a user controls the password to an account, without using the password. Similarly, these schemes work by bootstrapping off mobile devices, which ensure that the user who set up such a service with the credential issuing entity (a trusted third party) has the information that grants access to the protected resource. Part of Commonwealth's Identity Protocol is building tools for allowing a rich, decentralized ecosystem of credential or claims issuing entities to grow.

In the proposed anonymous credential issuance service, a predominantly off-chain issuance application, users will use the Commonwealth Protocol to structure and design the claims they wish to receive from trusted third parties. These interactions will happen off-chain, but will be verifiable on-chain, allowing users and trusted third-parties the ability to add new credentials (groups of claims) to ERC735 compliant identities. Thus, new applications such as those described with Github will be possible. When trusted third parties have incentives to participate in the system, users will benefit from being able to add these claims to their blockchain based identities and further participate in the ecosystem's rich set of protocols for lending, voting, and more.

Within this system, there are paths for obtaining public and private credentials. Alice may want to prove publicly that she is at least 21 years or by using a credential issued by a trusted third party such as her local, state, or federal government.

***SnarkBallot***

    pragma solidity ^0.4.22;
    
    import './MerkleTree.sol';
    import './Verified.sol';
    import './KeyHolder.sol';
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
                uint[] input
    		) returns (address);
    		function reveal(bytes32 unblindedCommitment) isCommit(commitAndReveal) returns (bool);
    		function votePrice(uint amount) constant returns (uint);
    		function isRoot(bytes32 root) constant returns(bool);
    		function nullifierToAddress(bytes32 source) returns(address);
    }

***SnarkUtil***

    pragma solidity ^0.4.22;
    
    library SnarkUtil {
    		function merge253bitWords(uint left, uint right) returns(bytes32);
    		function pad3bit(uint input) constant returns(uint);
    		function getZero(bytes32 x) returns(bytes32);
    		function padZero(bytes32 x) returns(bytes32);
    		function reverseByte(uint a) public pure returns (uint);
    		function reverse(bytes32 a) public pure returns(bytes32);
    }

***MerkleTree***

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

***RingBallot***
```
// Adapted from Clearmatics Mixer

pragma solidity ^0.4.22;

import '../crypto/LinkableRing.sol';
import '../token/ERC223ReceivingContract.sol';
import '../token/ERC20Compatible.sol';

contract RingBallot {
    using LinkableRing for LinkableRing.Data;
    
    struct Data {
        bytes32 guid;
        uint256 denomination;
        address token;
        LinkableRing.Data ring;
        bool usingCommitments;
        mapping (uint256 => bytes32) commitments;
        mapping (uint256 => bool) revealed;
        bytes32[] votes;
    }

    mapping(bytes32 => Data) internal m_rings;
    mapping(uint256 => bytes32) internal m_pubx_to_ring;
    mapping(bytes32 => bytes32) internal m_filling;
    uint256 internal m_ring_ctr;

    event RingBallotDeposit(bytes32 indexed ring_id, uint256 indexed pub_x, address token, uint256 value);
    event RingBallotVote(bytes32 indexed ring_id, uint256 tag_x, address uint256 value, bytes32 vote);
    event RingBallotReveal(bytes32 indexed ring_id, uint256 tag_x, address token, uint256 value, bytes32 vote);
    event RingBallotReady( bytes32 indexed ring_id, bytes32 message );
    event RingBallotDead( bytes32 indexed ring_id, bytes32[] votes );

    function lookupFillingRing (address token, uint256 denomination)
        internal returns (bytes32, Data storage);
    function message(bytes32 ring_guid)
        public view returns (bytes32);
    function depositEther(address token, uint256 denomination, uint256 pub_x, uint256 pub_y, bool usingCommitments)
        public payable returns (bytes32);
    function depositERC20Compatible(address token, uint256 denomination, uint256 pub_x, uint256 pub_y, bool usingCommitments)
        public returns (bytes32);
    function voteWithEther(bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist, bytes32 commitment)
        public returns (bool);
    function voteWithERC20Compatible(bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist, bytes32 commitment)
        public returns (bool);
    function revealWithEther(bytes32 ring_id, uint256 tag_x, bytes32 vote)
        public returns (bool);
    function revealWithERC20Compatible(bytes32 ring_id, uint256 tag_x, bytes32 vote)
        public returns (bool);
    function lookupFillingRing(address token, uint256 denomination, bool usingCommitments)
        internal returns (bytes32, Data storage);
    function depositLogic(address token, uint256 denomination, uint256 pub_x, uint256 pub_y, bool usingCommitments)
        internal returns (bytes32);
    function voteLogic(bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist, bytes32 commitment)
        internal returns (Data);
    function revealLogic(bytes32 ring_id, uint256 tag_x, bytes32 vote)
        internal returns (Data);
		function votePrice(uint amount) constant returns (uint);
}
```

## Conclusion

We have presented privacy preservation tools for identity and voting. We have discussed details of its implementation, as well as specific applications towards financial services, gaming, and blockchain governance. 

## References

- [https://github.com/OriginProtocol/identity-playground/blob/master/README.md](https://github.com/OriginProtocol/identity-playground/blob/master/README.md)
- [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md)
- [https://github.com/ethereum/EIPs/issues/735](https://github.com/ethereum/EIPs/issues/735)

---

@Raymond Z - describe UX of interacting with Miximus, since it requires interacting with many keys
