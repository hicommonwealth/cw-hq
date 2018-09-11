// Adapted from Clearmatics Mixer implementation for voting purposes

pragma solidity ^0.4.18;

import './LinkableRing.sol';


/**
* Each ring is given a globally unique ID which consist of:
*
*  - contract address
*  - incrementing nonce
*  - token address
*  - denomination
*
* When a Deposit is made for a specific Token and Denomination 
* the RingBallot will return the Ring GUID. The lifecycle of each Ring
* can then be monitored using the following events which demarcate
* the state transitions:
*
* RingBallotDeposit
*   For each Deposit a RingBallotDeposit message is emitted, this includes
*   the Ring GUID, the X point of the Stealth Address, and the Token
*   address and Denomination.
*
* RingBallotReady
*   When a Ring is full and withdrawals can be made a RingReady
*   event is emitted, this includes the Ring GUID and the Message
*   which must be signed to Withdraw.
*
* RingBallotVote
*   For each Vote a RingBallotVote message is emitted, this includes
*   the Token, Denomination, Ring GUID, Tag, and Vote of the withdrawer/voter.
*
* RingBallotDead
*   When all participants have withdrawn their tokens from a Ring the
*   RingBallotDead event is emitted, this specifies the Ring GUID.
*/
contract RingBallot
{
    using LinkableRing for LinkableRing.Data;
    
    struct Data {
        bytes32 guid;
        uint256 denomination;
        address token;
        LinkableRing.Data ring;

        // Allow new rings to select commitment scheme
        bool public commitAndReveal;

        // Map public keys to commitments
        mapping (uint256 => bytes32) commitments;

        // Map public keys to revealed boolean
        mapping (uint256 => bool) revealed;

        // Store votes in array for publishing
        bytes32[] votes;
    }

    mapping(bytes32 => Data) internal m_rings;

    /** With a public key, lookup which ring it belongs to */
    mapping(uint256 => bytes32) internal m_pubx_to_ring;

    /** Rings which aren't full yet, H(token,denom) -> ring_id */
    mapping(bytes32 => bytes32) internal m_filling;

    /** Nonce used to generate Ring Messages */
    uint256 internal m_ring_ctr;

    /**
    * Token has been deposited into a RingBallot Ring
    */
    event RingBallotDeposit(
        bytes32 indexed ring_id,
        uint256 indexed pub_x,
        address token,
        uint256 value
    );

    /**
    * Token has been withdraw from a RingBallot Ring
    */
    event RingBallotVote(
        bytes32 indexed ring_id,
        uint256 tag_x,
        address token,
        uint256 value,
        bytes32 vote,
    );

    event RingBallotReveal(
        bytes32 indexed ring_id,
        uint256 tag_x,
        address token,
        uint256 value,
        bytes32 vote,
    );

    /**
     * A RingBallot Ring is Full, Tokens can now be withdrawn from it
     */
    event RingBallotReady( bytes32 indexed ring_id, bytes32 message );

    /**
    * A RingBallot Ring has been fully with withdrawn, the Ring is dead.
    */
    event RingBallotDead( bytes32 indexed ring_id );


    function RingBallot()
        public
    {
        // Nothing ...
    }


    /**
    * Lookup an unfilled/filling ring for a given token and denomination,
    * this will create a new unfilled ring if none exists. When the ring
    * is full the 'filling' ring will be deleted.
    */
    function lookupFillingRing (address token, uint256 denomination)
        internal returns (bytes32, Data storage)
    {
        // The filling ID allows quick lookup for the same Token and Denomination
        var filling_id = sha256(token, denomination);
        var ring_guid = m_filling[filling_id];
        if( ring_guid != 0 )
            return (filling_id, m_rings[ring_guid]);

        // The GUID is unique per RingBallot instance, Nonce, Token and Denomination
        ring_guid = sha256(address(this), m_ring_ctr, filling_id);

        Data storage entry = m_rings[ring_guid];

        // Entry must be initialized only once
        require( 0 == entry.denomination );
        require( entry.ring.Initialize(ring_guid) );

        entry.guid = ring_guid;
        entry.token = token;
        entry.denomination = denomination;

        m_ring_ctr += 1;
        m_filling[filling_id] = ring_guid;

        return (filling_id, entry);
    }


    /**
    * Given a GUID of a full Ring, return the Message to sign
    */
    function Message (bytes32 ring_guid)
        public view returns (bytes32)
    {
        Data storage entry = m_rings[ring_guid];
        LinkableRing.Data storage ring = entry.ring;

        // Entry is empty, non-existant ring
        require( 0 != entry.denomination );

        return ring.Message();
    }


    /**
    * Deposit tokens of a specific denomination which can only be withdrawn
    * by providing a ring signature by one of the public keys.
    */
    function Deposit (address token, uint256 denomination, uint256 pub_x, uint256 pub_y)
        public payable returns (bytes32)
    {      
        // TODO: verify token is a valid ERC-223 contract

        require( token == 0 );
        require( denomination == msg.value );

        // Denomination must be positive power of 2, e.g. only 1 bit set
        require( denomination != 0 && 0 == (denomination & (denomination - 1)) );

        // Public key can only exist in one ring at a time
        require( 0 == uint256(m_pubx_to_ring[pub_x]) );

        bytes32 filling_id;
        Data storage entry;
        (filling_id, entry) = lookupFillingRing(token, denomination);

        LinkableRing.Data storage ring = entry.ring;

        require( ring.AddParticipant(pub_x, pub_y) );

        // Associate Public X point with Ring GUID
        // This allows the ring to be recovered with the public key
        // Without having to monitor/replay the RingDeposit events
        var ring_guid = entry.guid;
        m_pubx_to_ring[pub_x] = ring_guid;
        RingBallotDeposit(ring_guid, pub_x, token, denomination);

        // When full, emit the GUID as the Ring Message
        // Participants need to sign this Message to Withdraw
        if( ring.IsFull() ) {
            delete m_filling[filling_id];
            RingBallotReady(ring_guid, ring.Message());
        }

        return ring_guid;
    }


    /**
    * To Withdraw a Token of Denomination from the Ring, one of the Public Keys
    * must provide a Signature which has a unique Tag. Each Tag can only be used
    * once.
    */
    function Vote (bytes32 ring_id, uint256 tag_x, uint256 tag_y, uint256[] ctlist, bytes32 commitment)
        public returns (bool)
    {    
        Data storage entry = m_rings[ring_id];
        LinkableRing.Data storage ring = entry.ring;

        // Entry is empty, non-existant ring
        require( 0 != entry.denomination );

        require( ring.IsFull() );

        require( ring.SignatureValid(tag_x, tag_y, ctlist) );

        // Tag must be added before vote
        ring.TagAdd(tag_x);

        RingBallotVote(ring_id, tag_x, entry.token, entry.denomination, commitment);

        // TODO: add ERC-223 support
        if (!entry.commitAndReveal) {
            // If not commit and reveal scheme, ensure voter cannot re-vote
            require( !entry.revealed[pub_x] );

            entry.votes.push(commitment);
            entry.revealed[pub_x] = true;
            msg.sender.transfer(entry.denomination);
            // When Tags.length == Pubkeys.length, the ring is dead
            // Remove mappings and delete ring
            if( ring.IsDead() ) {
                for( uint i = 0; i < ring.pubkeys.length; i++ ) {
                    delete m_pubx_to_ring[ring.pubkeys[i].X];
                }

                // publish results of vote before deleting ring and its contents
                RingBallotDead(ring_id, entry.votes);
                delete m_rings[ring_id];
            }
        } else {
            entry.commitments[pub_x] = commitment;
        }

        return true;
    }

    function Reveal (bytes32 ring_id, bytes32 vote, pub_x) public returns (bool) {
        Data storage entry = m_rings[ring_id];
        LinkableRing.Data storage ring = entry.ring;

        // Require all commitments to be submitted
        require( ring.IsDead() );

        // Require public key to not have revealed yet in the ring
        require( !entry.revealed[pub_x] )

        // Require revealed vote to match committed vote under SHA3 of public key
        require( sha3(vote) == entry.commitments[pub_x] );

        entry.votes.push(vote);
        entry.revealed[pub_x] = true;
        msg.sender.transfer(entry.denomination);

        // When votes.length == Pubkeys.length, the ring's votes are fully revealed
        // Remove mappings and delete ring
        if( entry.votes.length == ring.pubkeys.length ) {
            for( uint i = 0; i < ring.pubkeys.length; i++ ) {
                delete m_pubx_to_ring[ring.pubkeys[i].X];
            }

            RingBallotDead(ring_id, entry.votes);
            delete m_rings[ring_id];
        }
    }


    function () public {
        revert();
    }
}