pragma solidity ^0.4.24;

import "openzeppelin-zos/contracts/math/SafeMath.sol";

/**
 * The LockDrop contract locks up funds of depositors
 * with a verifiable receipt/proof that can be used to
 * redeem tokens on a separate, compatible blockchain.
 * THe tokens with be locked for a specified time length.
 */
contract LockDrop {
    uint public lockDropCapacity;
    uint public lockDropBeginning;
    uint public lockDropEnding;

    mapping (address => uint) lockDropBalances;

    constructor(uint length, uint capacity) {
        lockDropCapacity = capacity;
        lockDropBeginning = now;
        lockDropEnding = now * length * 1 day;
    }

    function lock() payable public {
        require(now <= lockDropEnding);
        uint balance = lockDropBalances[msg.sender]
        lockDropBalances[msg.sender] = SafeMath.add(balance, msg.value);
    }
    
    function withdraw() public {
        require(now > lockDropEnding);
        require(lockDropBalances[msg.sender] > 0);
        msg.sender.transfer(lockDropBalances[msg.sender]);
    }
    
}
