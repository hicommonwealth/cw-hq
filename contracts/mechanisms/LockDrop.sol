pragma solidity ^0.4.24;

import "openzeppelin-zos/contracts/math/SafeMath.sol";
import "../token/EdgewareERC20.sol";

/**
 * The LockDrop contract locks up funds of depositors
 * with a verifiable receipt/proof that can be used to
 * redeem tokens on a separate, compatible blockchain.
 * The tokens with be locked for a specified time length.
 * 
 * The tokens are minted at a rate that grows according
 * to the chosen locking schedule.
 */
contract LockDrop {
    uint public capacity;
    uint public beginning;
    uint public ending;
    uint public maxLength;

    struct Lock {
        uint amount;
        uint lockEnding;
    }

    mapping (address => Lock[]) locks;

    event Deposit(address sender, uint value, uint length, uint ending);
    event Unlock(address sender, uint value);
    event Withdraw(address sender, uint value);

    constructor(uint _lockPeriod, uint _maxLength, uint _capacity) public {
        beginning = now;
        ending = now + (1 days * _lockPeriod);
        capacity = _capacity;
        maxLength = _maxLength;
    }

    /**
     * @dev        Lock function for participating in the lock drop
     * @param      _length  The length of time chosen for locking ether
     */
    function lock(uint _length) payable public {
        require(hasNotEnded());
        require(_length <= maxLength);
        require(msg.value <= capacity && msg.value > 0);
        capacity -= msg.value;

        // Create deposit with paid amount and specified length
        // of time. The lock ending is determined as the specified
        // time length after the ending of the lock up period in days.
        Lock memory l = Lock({
            amount: msg.value,
            lockEnding: ending + (_length * 1 days)
        });

        // Push new deposit
        locks[msg.sender].push(l);

        // Emit Deposit event
        emit Deposit(msg.sender, msg.value, _length, l.lockEnding);
    }
    
    /**
     * @dev        Unlock function reverts the lock before the lock starts
     * @param      _lockIndex  The deposit index to unlock
     */
    function unlock(uint _lockIndex) public {
        require(hasNotEnded());
        require(locks[msg.sender].length > _lockIndex);

        // Save amount to memory and delete the lock
        Lock memory l = locks[msg.sender][_lockIndex];
        delete locks[msg.sender][_lockIndex];

        // Send the funds back to owner
        msg.sender.transfer(l.amount);

        // Emit Unlock event
        emit Unlock(msg.sender, l.amount);
    }

    /**
     * @dev        Withdraw function should withdraw all valid ether after lock
     */
    function withdraw() public {
        require(hasEnded());
        require(locks[msg.sender].length > 0);

        uint amount = 0;

        // Iterate over all locks
        for (uint i = 0; i < locks[msg.sender].length; i++) {
            Lock memory curr = locks[msg.sender][i];
            
            // Aggregate deposit if ending has passed and lockEnding is valid
            if (now >= curr.lockEnding && curr.lockEnding != 0) {
                amount = SafeMath.add(amount, curr.amount);
                delete locks[msg.sender][i];
            }
        }

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function hasNotEnded() public constant returns (bool) {
        return now <= ending;
    }

    function hasEnded() public constant returns (bool) {
        return now > ending;
    }
}
