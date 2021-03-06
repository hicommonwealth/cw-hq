import { getCurrentTimestamp, advanceTimeAndBlock } from '../../helpers/evmTime.js';
import assertRevert from '../../helpers/assertRevert.js';
import getLockDropDeposits from "../../helpers/lockDropLogParser.js";
const { toWei, toBN, padRight } = web3.utils;

const LockDrop = artifacts.require("./LockDrop.sol");

contract('LockDrop', (accounts) => {
  const secondsInDay = 86400;
  let lockDrop;
  let tokenPrice;
  let tokenCapacity;

  beforeEach(async () => {
    const numDays = 1;
    tokenCapacity = 100;
    tokenPrice = toWei("1", "ether");

    lockDrop = await LockDrop.new(numDays, tokenCapacity, tokenPrice);
  });

  it("should initialize", async () => {
    const numDays = 10;
    const tokenCapacity = 100;
    const price = 1;

    const currentTimestamp = await getCurrentTimestamp();
    const lockDrop = await LockDrop.new(numDays, tokenCapacity, price);

    const _tokenCapacity = await lockDrop.tokenCapacity();
    const _price = await lockDrop.tokenPrice();
    const _ending = await lockDrop.ending();

    assert.equal(_tokenCapacity.toNumber(), tokenCapacity);
    assert.equal(_price.toNumber(), price);

    const secondsInDay = 60 * 60 * 24;
    assert.isTrue(_ending.toNumber() >= currentTimestamp + (secondsInDay * 10));
  });

  it("should be able to lock deposit", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    const lock = await lockDrop.getLockAt(accounts[0], 0);
    const ending = await lockDrop.ending();
    const tokensLeft = await lockDrop.tokenCapacity();

    const bonus = value.mul(toBN(toWei("3.75", "ether"))).div(toBN(toWei("100", "ether")));
    const effectiveAmount = bonus.add(value);
    const numberOfTokens = effectiveAmount.div(toBN(tokenPrice));
    const lockEnding = ending.add(toBN(secondsInDay).mul(toBN(daysInSixMonths)));

    assert.equal(lock[0].toString(), toWei("10", "ether"));
    assert.equal(lock[1].toNumber(), numberOfTokens.toNumber());
    assert.equal(lock[2].toNumber(), lockEnding.toNumber());
    assert.equal(tokensLeft.toNumber(), tokenCapacity - numberOfTokens.toNumber());
  });

  it("should not be able to lock deposit after the lockdrop ends", async () => {
    await advanceTimeAndBlock(secondsInDay + 1);
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    assertRevert(lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    }));
  });

  it("should be able to correctly emit event amid deposit", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    const tx = await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    const logArgs = tx.logs[0].args;

    assert.equal(logArgs.sender, accounts[0]);
    assert.equal(logArgs.numOfTokens.toString(), "10");
    assert.equal(logArgs.receiver, padRight("0x01", 64));
    assert.equal(logArgs.lockIndex.toNumber(), 0);
  });

  it("should be able to unlock deposit before the lockdrop end", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    await lockDrop.unlock(0);

    const lock = await lockDrop.getLockAt(accounts[0], 0);
    const tokensLeft = await lockDrop.tokenCapacity();

    assert.equal(lock[0].toString(), "0");
    assert.equal(lock[1].toNumber(), 0);
    assert.equal(lock[2].toNumber(), 0);
    assert.equal(tokensLeft, tokenCapacity);
  });

  it("should not be able to unlock after the lockdrop ends", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    await advanceTimeAndBlock(secondsInDay + 1);

    await assertRevert(lockDrop.unlock(0));

    const lock = await lockDrop.getLockAt(accounts[0], 0);
    const ending = await lockDrop.ending();
    const tokensLeft = await lockDrop.tokenCapacity();

    const bonus = value.mul(toBN(toWei("3.75", "ether"))).div(toBN(toWei("100", "ether")));
    const effectiveAmount = bonus.add(value);
    const numberOfTokens = effectiveAmount.div(toBN(tokenPrice));
    const lockEnding = ending.add(toBN(secondsInDay).mul(toBN(daysInSixMonths)));

    assert.equal(lock[0].toString(), toWei("10", "ether"));
    assert.equal(lock[1].toNumber(), numberOfTokens.toNumber());
    assert.equal(lock[2].toNumber(), lockEnding.toNumber());
    assert.equal(tokensLeft.toNumber(), tokenCapacity - numberOfTokens.toNumber());
  });

  it("should be able to correctly emit event amid unlock", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    const tx = await lockDrop.unlock(0);
    const logArgs = tx.logs[0].args;

    assert.equal(logArgs.sender, accounts[0]);
    assert.equal(logArgs.lockIndex.toNumber(), 0)
  });

  it("should be able to withdraw locks after lock period ended", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    await advanceTimeAndBlock(secondsInDay + 1);
    await advanceTimeAndBlock((daysInSixMonths * secondsInDay) + 1);

    await lockDrop.withdraw();

    const bonus = value.mul(toBN(toWei("3.75", "ether"))).div(toBN(toWei("100", "ether")));
    const effectiveAmount = bonus.add(value);
    const numberOfTokens = effectiveAmount.div(toBN(tokenPrice));

    const lock = await lockDrop.getLockAt(accounts[0], 0);
    const tokensLeft = await lockDrop.tokenCapacity();

    assert.equal(lock[0].toString(), "0");
    assert.equal(lock[1].toNumber(), 0);
    assert.equal(lock[2].toNumber(), 0);
    assert.equal(tokensLeft, tokenCapacity - numberOfTokens.toNumber());
  });

  it("should not be able to withdraw deposit before lock drop has ended", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: value.toString()
    });

    await assertRevert(lockDrop.withdraw());

    await advanceTimeAndBlock(secondsInDay + 1);

    const lock = await lockDrop.getLockAt(accounts[0], 0);
    const ending = await lockDrop.ending();
    const tokensLeft = await lockDrop.tokenCapacity();

    const bonus = value.mul(toBN(toWei("3.75", "ether"))).div(toBN(toWei("100", "ether")));
    const effectiveAmount = bonus.add(value);
    const numberOfTokens = effectiveAmount.div(toBN(tokenPrice));
    const lockEnding = ending.add(toBN(secondsInDay).mul(toBN(daysInSixMonths)));

    assert.equal(lock[0].toString(), toWei("10", "ether"));
    assert.equal(lock[1].toNumber(), numberOfTokens.toNumber());
    assert.equal(lock[2].toNumber(), lockEnding.toNumber());
    assert.equal(tokensLeft.toNumber(), tokenCapacity - numberOfTokens.toNumber());
  });

  it("should calculate the bonus correctly for different lock durations", async () => {
    const amount = 100;
    // Three months
    let lengthInDays = 91;
    const multiplier = toBN(toWei("3.75", "ether"));

    let effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    assert.equal(effectiveAmount.toNumber(), amount);

    // Six months
    lengthInDays = 182;
    effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    let bonus = toBN(amount).mul(multiplier).div(toBN(toWei("100", "ether")));
    let correctAmount = toBN(amount).add(bonus);
    assert.equal(effectiveAmount.toNumber(), correctAmount.toNumber());

    // One year
    lengthInDays = 364;
    effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    bonus = toBN(amount).mul(multiplier.mul(toBN(2))).div(toBN(toWei("100", "ether")));
    correctAmount = toBN(amount).add(bonus);
    assert.equal(effectiveAmount.toNumber(), correctAmount.toNumber());

    // One and a half years
    lengthInDays = 546;
    effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    bonus = toBN(amount).mul(multiplier.mul(toBN(3))).div(toBN(toWei("100", "ether")));
    correctAmount = toBN(amount).add(bonus);
    assert.equal(effectiveAmount.toNumber(), correctAmount.toNumber());

    // Two years
    lengthInDays = 728;
    effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    bonus = toBN(amount).mul(multiplier.mul(toBN(4))).div(toBN(toWei("100", "ether")));
    correctAmount = toBN(amount).add(bonus);
    assert.equal(effectiveAmount.toNumber(), correctAmount.toNumber());

    // Two and a half years
    lengthInDays = 910;
    effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    // Same as two years
    assert.equal(effectiveAmount.toNumber(), correctAmount.toNumber());

    // Four years
    lengthInDays = 1820;
    effectiveAmount = await lockDrop.calculateEffectiveAmount(amount, lengthInDays);
    // Same as two years
    assert.equal(effectiveAmount.toNumber(), correctAmount.toNumber());
  });

  it("should not be able to lock ether if passes amount is not enought for at least 1 token", async () => {

  });

  it("should be able to work with extremely low values", async () => {
    const numDays = 1;
    const tokenCapacity = 1;
    const tokenPrice = 1; // 1 wei

    const lockDrop = await LockDrop.new(numDays, tokenCapacity, tokenPrice);

    const daysInSixMonths = 182;
    await lockDrop.lock(daysInSixMonths, "0x01", {
      value: 1
    });

    const lock = await lockDrop.getLockAt(accounts[0], 0);
    const ending = await lockDrop.ending();
    const tokensLeft = await lockDrop.tokenCapacity();

    assert.equal(lock[0].toString(), 1);
    assert.equal(lock[1].toNumber(), 1);
    assert.equal(tokensLeft.toNumber(), 0);
  });

  it("should be able to work with extremely high values", async () => {
    const multiplier = toBN("15000000000000000000");
    const maxSolidityNumber = toBN(2).pow(toBN(256)).sub(toBN(1));
    const maxValueToPass = maxSolidityNumber.div(multiplier);
    const numDays = 1;
    const tokenCapacity = toBN(2).pow(toBN(256)).sub(toBN(1));
    const tokenPrice = 1; // 1 wei
    const lockDrop = await LockDrop.new(numDays, tokenCapacity, tokenPrice);

    const lengthInDays = 728;
    const res = await lockDrop.calculateEffectiveAmount(maxValueToPass.toString(), lengthInDays);
    const fifteenPercent = maxValueToPass.mul(toBN(15)).div(toBN(100));

    assert.equal(toBN(res).toString(), maxValueToPass.add(fifteenPercent).toString());

    // Overflow if we add 1
    await assertRevert(lockDrop.calculateEffectiveAmount(maxValueToPass.add(toBN(1)).toString(), lengthInDays));

    // Not possible to test this since by the default accounts have only 100 eth
  });

  it("should be able to get all participants trought events after lock drop has ended", async () => {
    const daysInSixMonths = 182;
    const value = toBN(toWei("10", "ether"));
    // key - 0x01
    const key1 = padRight("0x01", 64);
    await lockDrop.lock(daysInSixMonths, key1, {
      value: value.toString()
    });
    await lockDrop.lock(daysInSixMonths, key1, {
      value: value.toString()
    });
    await lockDrop.unlock(0);

    // key - 0x02
    const key2 = padRight("0x02", 64);
    const account2 = accounts[2];
    await lockDrop.lock(daysInSixMonths, key2, {
      value: value.toString(),
      from: account2
    });
    await lockDrop.lock(daysInSixMonths, key2, {
      value: value.toString(),
      from: account2
    });
    await lockDrop.unlock(1, {
      from: account2
    });

    // key - 0x03
    const key3 = padRight("0x03", 64);
    const account3 = accounts[3];
    await lockDrop.lock(daysInSixMonths, key3, {
      value: value.toString(),
      from: account3
    });
    await lockDrop.lock(daysInSixMonths, key3, {
      value: value.toString(),
      from: account3
    });
    await lockDrop.unlock(0, {
      from: account3
    });
    await lockDrop.unlock(1, {
      from: account3
    });

    // key - 0x04
    const key4 = padRight("0x04", 64);
    const account4 = accounts[4];
    await lockDrop.lock(daysInSixMonths, key4, {
      value: value.toString(),
      from: account4
    });
    await lockDrop.lock(daysInSixMonths, key4, {
      value: value.toString(),
      from: account4
    });
    await lockDrop.lock(daysInSixMonths, key4, {
      value: value.toString(),
      from: account4
    });
    await lockDrop.unlock(2, {
      from: account4
    });

    // key - 0x05
    const key5 = padRight("0x05", 64);
    const account5 = accounts[5];
    await lockDrop.lock(daysInSixMonths, key5, {
      value: value.toString(),
      from: account5
    });
    await lockDrop.lock(daysInSixMonths, key5, {
      value: value.toString(),
      from: account5
    });
    await lockDrop.lock(daysInSixMonths, key5, {
      value: value.toString(),
      from: account5
    });

    const key6 = padRight("0x06", 64);
    const account6 = accounts[6];
    await lockDrop.lock(daysInSixMonths, key6, {
      value: value.toString(),
      from: account6
    });
    await lockDrop.unlock(0, {
      from: account6
    });

    await advanceTimeAndBlock(secondsInDay + 1);

    const contract = new web3.eth.Contract(lockDrop.abi, lockDrop.address);
    const [receivers, genesisConfigBalances] = await getLockDropDeposits(contract);

    assert.equal(receivers[key1], "10");
    assert.equal(receivers[key2], "10");
    // Zero values are not saved
    assert.isUndefined(receivers[key3]);
    assert.equal(receivers[key4], "20");
    assert.equal(receivers[key5], "30");
    assert.isUndefined(receivers[key6]);

    assert.equal(genesisConfigBalances[0][0], key1);
    assert.equal(genesisConfigBalances[0][1], "10");

    assert.equal(genesisConfigBalances[1][0], key2);
    assert.equal(genesisConfigBalances[1][1], "10");

    assert.equal(genesisConfigBalances[2][0], key4);
    assert.equal(genesisConfigBalances[2][1], "20");

    assert.equal(genesisConfigBalances[3][0], key5);
    assert.equal(genesisConfigBalances[3][1], "30");

    assert.isUndefined(genesisConfigBalances[4]);
  });
});
