pragma solidity ^0.4.24;

import "openzeppelin-zos/contracts/math/SafeMath.sol";
import "openzeppelin-zos/contracts/math/Math.sol";
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
    EdgewareERC20 EDG;

    uint public tokenCapacity;
    uint public totalDeposits;
    uint public totalEffectiveDeposits;
    uint public initialValuation;
    uint public globalPriceFloor;

    uint public beginning;
    uint public ending;

    struct Lock {
        uint amount;
        uint effectiveAmount;
        uint lockEnding;
    }

    mapping (address => Lock[]) locks;

    event Deposit(address sender, uint value, uint effectiveValue, uint ending);
    event Unlock(address sender, uint value);
    event Withdraw(address sender, uint value, uint effectiveValue);

    constructor(uint _lockPeriod, uint _tokenCapacity, uint _initialValuation, uint _priceFloor) public {
        beginning = now;
        ending = now + (1 days * _lockPeriod);
        tokenCapacity = _tokenCapacity;
        initialValuation = _initialValuation;
        globalPriceFloor = _priceFloor;

        EDG = new EdgewareERC20();
    }

    /**
     * @dev        Lock function for participating in the lock drop
     * @param      _length  The length of time chosen for locking ether
     */
    function lock(uint _length) payable public {
        require( hasNotEnded() );
        require( msg.value > 0 );
        require( tokenCapacity > 0 );

        uint dayLength = SafeMath.mul(_length, 1 days);
        require( isValidLength(dayLength) );

        uint discountAmount = discountedDepositValue(msg.value, dayLength);
        totalDeposits = SafeMath.add(totalDeposits, msg.value);
        totalEffectiveDeposits = SafeMath.add(totalEffectiveDeposits, effectiveAmount);

        // TODO: Make sure price floor and initial valuation are valid units
        uint price = Math.max256(globalPriceFloor, SafeMath.div(totalDeposits, initialValuation));
        uint effectiveAmount = SafeMath.mul(discountAmount, price);

        // Ensure effectiveAmount is less than tokens left
        require( effectiveAmount < tokenCapacity );
        tokenCapacity = SafeMath.sub(tokenCapacity, effectiveAmount);

        // Create deposit with paid amount and specified length
        // of time. The lock ending is determined as the specified
        // time length after the ending of the lock up period in days.
        Lock memory l = Lock({
            amount: msg.value,
            effectiveAmount: effectiveAmount,
            lockEnding: SafeMath.add(ending, dayLength)
        });

        // Push new deposit
        locks[msg.sender].push(l);

        // Emit Deposit event
        emit Deposit(msg.sender, l.amount, l.effectiveAmount, l.lockEnding);
    }
    
    /**
     * @dev        Unlock function reverts the lock before the lock starts
     * @param      _lockIndex  The deposit index to unlock
     */
    function unlock(uint _lockIndex) public {
        require( hasNotEnded() );
        require( locks[msg.sender].length > _lockIndex );

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
        require( hasEnded() );
        require( locks[msg.sender].length > 0 );

        uint amount = 0;
        uint effectiveAmount = 0;

        // Iterate over all locks
        for (uint i = 0; i < locks[msg.sender].length; i++) {
            Lock memory curr = locks[msg.sender][i];
            
            // Aggregate deposit if ending has passed and lockEnding is valid
            if (now >= curr.lockEnding && curr.lockEnding != 0) {
                amount = SafeMath.add(amount, curr.amount);
                effectiveAmount = SafeMath.add(effectiveAmount, curr.effectiveAmount);
                delete locks[msg.sender][i];
            }
        }

        msg.sender.transfer(amount);
        EDG.mint(msg.sender, effectiveAmount);

        emit Withdraw(msg.sender, amount, effectiveAmount);
    }

    function discountedDepositValue(uint value, uint length) internal constant returns (uint) {
        uint effectiveValue = 0;

        // TODO: Ensure units are safe to use
        if (length == 91 days) {
            effectiveValue = value;
        } else if (length == 182 days) {
            effectiveValue = (value * 3.75 ether) / 100 ether;
        } else if (length == 365 days) {
            effectiveValue = (value * 7.5 ether) / 100 ether;
        } else if (length == 730 days) {
            effectiveValue = (value * 15 ether) / 100 ether;
        } else if (length == 1095 days) {
            effectiveValue = (value * 15 ether) / 100 ether;
        } else {
            revert();
        }

        return effectiveValue;
    }

    function isValidLength(uint length) internal constant returns (bool) {
        if (length == 91 days) {
            return true;
        } else if (length == 182 days) {
            return true;
        } else if (length == 365 days) {
            return true;
        } else if (length == 730 days) {
            return true;
        }

        return false;
    }
    
    function getTotalLocks(address sender) public constant returns (uint) {
        return locks[sender].length;
    }

    function hasNotEnded() public constant returns (bool) {
        return now <= ending;
    }

    function hasEnded() public constant returns (bool) {
        return now > ending;
    }
}
