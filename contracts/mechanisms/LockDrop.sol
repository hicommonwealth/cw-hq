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

    struct Deposit {
        uint amount;
        uint lockEnding;
    }
    
    mapping (address => Deposit[]) deposits;

    constructor(uint _lockPeriod, uint _maxLength, uint _capacity) {
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
        require(now <= ending);

        // Create deposit with paid amount and specified length
        // of time. The lock ending is determined as the specified
        // time length after the ending of the lock up period in days.
        Deposit d = Deposit({
            amount: msg.value,
            lockEnding: ending + (_length * 1 days)
        });

        // Push new deposit
        deposits[msg.sender].push(d);

        // TODO: Emit Deposit event
    }
    
    /**
     * @dev        Unlock function reverts the lock before the lock starts
     * @param      _depositIndex  The deposit index to unlock
     */
    function unlock(uint _depositIndex) public {
        require(now <= ending);
        require(deposits[msg.sender].length > _depositIndex);

        uint memory amount = deposits[msg.sender][_depositIndex].amount;
        delete deposits[msg.sender][_depositIndex];

        msg.sender.transfer(amount);
    }
    

    /**
     * @dev        Withdraw function should withdraw all valid ether after lock
     */
    function withdraw() public {
        require(now > ending);
        
        uint totalAmount = 0;

        // Iterate over all deposits
        for (uint i = 0; i < deposits[msg.sender].length; i++) {
            Deposit curr = deposits[msg.sender][i];
            
            // Aggregate deposit if ending has passed and lockEnding is valid
            if (now >= curr.lockEnding && curr.lockEnding != 0) {
                totalAmount = SafeMath.add(totalAmount, curr.amount);
                delete deposits[msg.sender][i];
            }
        }

        msg.sender.transfer(totalAmount);
    }    
}
