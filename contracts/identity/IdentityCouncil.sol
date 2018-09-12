pragma solidity ^0.4.24;

import './CommonwealthIdentity.sol';

contract IdentityCouncil {

    mapping (address => CommonwealthIdentity) councilIndex;
    CommonwealthIdentity[] council;

    constructor(address[] trustedIdentities) {
        if (trustedIdentities.length > 0) {
            for (uint i = 0; i < trustedIdentities.length; i++) {
                CommonwealthIdentity identity = trustedIdentities[i];
                councilIndex[council.length++] = identity;
                council[i] = identity;
            }
        }
    }
    
    function vote() {

    }

    function add() {

    }

    function remove() {

    }
}
