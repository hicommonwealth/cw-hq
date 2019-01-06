pragma solidity ^0.4.24;

import "./Math.sol";

/**
 * The LockDrop contract locks up funds of depositors
 * with a verifiable receipt/proof that can be used to
 * redeem tokens on a separate, compatible blockchain.
 * The tokens with be locked for a specified time length.
 *
 * The tokens are minted at a rate that grows according
 * to the chosen locking schedule.
 */
contract LockDrop is DSMath {
    uint constant THREE_MONTHS = 91;
    uint constant SIX_MONTHS = 182;

    uint public tokenCapacity;
    uint public tokenPrice;
    uint public ending;

    struct Lock {
        uint amount;
        uint numOfTokens;
        uint lockEnding;
    }

    mapping (address => Lock[]) locks;

    event Deposit(address indexed sender, uint numOfTokens, bytes32 indexed receiver, uint lockIndex);
    event Unlock(address indexed sender, uint lockIndex);
    event Withdraw(address indexed sender, uint value);

    modifier hasNotEnded() {
        require(now <= ending, "lock-drop-ended");
        _;
    }

    modifier hasEnded() {
        require(now > ending, "lock-drop-still-active");
        _;
    }

    constructor(uint _lockPeriodInDays, uint _tokenCapacity, uint _tokenPrice) public {
        ending = add(now, mul(1 days, _lockPeriodInDays));
        tokenCapacity = _tokenCapacity;
        tokenPrice = _tokenPrice;
    }

    /**
     * @dev        Lock function for participating in the lock drop
     * @param      _lengthInDays  Number of days chosen for locking ether
     */
    function lock(uint _lengthInDays, bytes32 _receivingPubKey) payable public hasNotEnded {
        require(msg.value > 0, "invalid-value");
        require(tokenCapacity > 0, "no-more-tokens-available");
        require(_receivingPubKey != 0x0, "invalid-public-key");

        // Calculate the bonus we want to give to a sender based on lock duration
        uint effectiveAmount = calculateEffectiveAmount(msg.value, _lengthInDays);
        require(effectiveAmount >= tokenPrice, "insufficient-amount-for-minimum-purchase");
        // Calculate how much tokens sender is buying
        uint numOfTokens = effectiveAmount / tokenPrice;

        // Ensure effectiveAmount is less or equal than tokens left
        require(numOfTokens <= tokenCapacity, "amount-exceeds-available-tokens");
        tokenCapacity = sub(tokenCapacity, numOfTokens);

        // Create deposit with paid amount and specified length
        // of time. The lock ending is determined as the specified
        // time length after the ending of the lock up period in days.
        Lock memory l = Lock({
            amount: msg.value,
            numOfTokens: numOfTokens,
            lockEnding: add(ending, mul(_lengthInDays, 1 days))
        });
        locks[msg.sender].push(l);

        // Emit Deposit event
        emit Deposit(msg.sender, numOfTokens, _receivingPubKey, locks[msg.sender].length - uint(1));
    }

    /**
     * @dev        Unlock function reverts the lock before the lock starts
     * @param      _lockIndex  The deposit index to unlock
     */
    function unlock(uint _lockIndex) public hasNotEnded {
        require(locks[msg.sender].length > _lockIndex, "lock-not-found");
        // Don't spend users gas if deposit is already unlocked
        require(locks[msg.sender][_lockIndex].amount > 0, "deposit-already-unlocked");

        // Save amount to memory and delete the lock
        Lock memory l = locks[msg.sender][_lockIndex];
        delete locks[msg.sender][_lockIndex];

        // Make the tokens available for other buyers
        tokenCapacity = add(tokenCapacity, l.numOfTokens);

        // Send the funds back to owner
        msg.sender.transfer(l.amount);

        // Emit Unlock event
        emit Unlock(msg.sender, _lockIndex);
    }

    /**
     * @dev        Withdraw function should withdraw all valid ether after lock
     */
    function withdraw() public hasEnded {
        require(locks[msg.sender].length > 0, "no-locks-found");

        uint amount = 0;

        // Iterate over all locks
        for (uint i = 0; i < locks[msg.sender].length; i++) {
            Lock memory curr = locks[msg.sender][i];

            // Aggregate deposit if ending has passed and lockEnding is valid
            if (now >= curr.lockEnding && curr.lockEnding != 0) {
                amount = add(amount, curr.amount);
                delete locks[msg.sender][i];
            }
        }
        // We dont want to spend users gas if there is no amount locked
        require(amount > 0, "no-locked-amount-found");

        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

    function calculateEffectiveAmount(uint _value, uint _length) public pure returns (uint _effectiveValue) {
        require(_length >= THREE_MONTHS, "invalid-lock-duration");

        if (_length < SIX_MONTHS) {
          return _value;
        }

        // maximum period is 2 years (4 * SIX_MONTHS)
        uint period = min(4, _length / SIX_MONTHS);
        uint bonus = mul(_value, mul(period, 3.75 ether)) / 100 ether;
        uint effectiveValue = add(_value, bonus);
        return effectiveValue;
    }

    function getTotalLocks(address _user) public view returns (uint _length) {
        return locks[_user].length;
    }

    function getLockAt(address _user, uint _index) public view returns (uint amount, uint numOfTokens, uint lockEnding) {
        return (locks[_user][_index].amount, locks[_user][_index].numOfTokens, locks[_user][_index].lockEnding);
    }
}
