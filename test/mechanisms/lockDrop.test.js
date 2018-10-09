import Promise from 'bluebird';
import assertRevert from '../../helpers/assertRevert';
import decodeLogs from '../../helpers/decodeLogs';
import { advanceTimeAndBlock } from '../../helpers/evmTime';
import { watchEvent } from '../../helpers/eventUtil';
import { getBalance } from '../../helpers/web3Util';

const LockDrop = artifacts.require("./LockDrop.sol");

contract('LockDrop', (accounts) => {
  let contract;

  // 10 ether
  let capacity = 1e19;

  // 1 day lock drop window
  let lockPeriodInDays = 1;

  // Max length of 1 day lock
  let maxLengthInDays = 1;

  beforeEach(async () => {
    contract = await LockDrop.new(lockPeriodInDays, maxLengthInDays, capacity);
  });

  it('should initialize with the correct parameters', async function () {
    assert.equal((await contract.capacity()).toNumber(), capacity);
    
    const beginning = (await contract.beginning()).toNumber();
    const ending = (await contract.ending()).toNumber();

    assert.equal(beginning + lockPeriodInDays * 86400, ending);
    assert.equal((await contract.maxLength()).toNumber(), maxLengthInDays);
  });

  it('should fail to lock 0 ether', async function () {
    await assertRevert(contract.lock(0, {
      from: accounts[1],
      value: 0,
    }));
  });

  it('should fail to lock for a length greater than the maximum length', async function () {
    await assertRevert(contract.lock(2, {
      from: accounts[1],
      value: web3.toWei(1, 'ether'),
    }));
  });

  it('should fail to unlock a non-existent lock', async function () {
    await assertRevert(contract.unlock(0, {
      from: accounts[1],
    }));
  });

  it('should fail to withdraw with no locks', async function () {
    await advanceTimeAndBlock((lockPeriodInDays * 86400) + 1);
    assert.ok(await contract.hasEnded());
    await assertRevert(contract.withdraw({
      from: accounts[0],
    }));
  });

  it('should fail to withdraw before the ending has been reached', async function () {
    assert.ok(await contract.hasNotEnded());
    await assertRevert(contract.withdraw({
      from: accounts[0],
    }));
  });

  it('should fail to lock after lock period has passed', async function () {
    await advanceTimeAndBlock((lockPeriodInDays * 86400) + 1);
    await assertRevert(contract.lock(0, {
      from: accounts[0],
      value: web3.toWei(1, 'ether'),
    }));
  });

  it('should lock 1 eth', async function () {
    await contract.lock(1, {
      from: accounts[0],
      value: web3.toWei(1, 'ether'),
    });

    const logs = await watchEvent(contract, { event: 'Deposit' });
    assert.equal(logs[0].args.sender, accounts[0]);
    assert.equal(logs[0].args.value.toNumber(), 1);
    assert.equal(logs[0].args.length.toNumber(), 1);
  });

  it('should unlock 1 eth', async function () {
    const wayBeforeBalance = (await getBalance(accounts[0])).toNumber();

    await contract.lock(1, {
      from: accounts[0],
      value: web3.toWei(1, 'ether'),
    });

    const beforeBalance = (await getBalance(accounts[0])).toNumber();

    await contract.unlock(0, {
      from: accounts[0],
    });

    const afterBalance = (await getBalance(accounts[0])).toNumber();

    const logs = await watchEvent(contract, { event: 'Unlock' });
    assert.equal(logs[0].args.sender, accounts[0]);
    assert.equal(logs[0].args.value.toNumber(), web3.toWei(1, 'ether'));
    assert.ok(wayBeforeBalance > beforeBalance && afterBalance > beforeBalance);
  });
});