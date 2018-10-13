import Promise from 'bluebird';
import assertRevert from '../../helpers/assertRevert';
import decodeLogs from '../../helpers/decodeLogs';
import { advanceTimeAndBlock } from '../../helpers/evmTime';
import { watchEvent } from '../../helpers/eventUtil';
import { getBalance } from '../../helpers/web3Util';

const LockDrop = artifacts.require("./LockDrop.sol");

contract('LockDrop', (accounts) => {
  let contract;

  let lockPeriod = 1;
  let tokenCapacity = 1e27;
  let initialValuation = 1e16;
  let priceFloor = 1

  const THREE_MONTHS = 91;
  const SIX_MONTHS = 182;
  const ONE_YEARS = 365;
  const TWO_YEARS = 730;
  const THREE_YEARS = 1095;

  beforeEach(async () => {
    contract = await LockDrop.new(lockPeriod, tokenCapacity, initialValuation, priceFloor);;
  });

  it('should initialize with the correct parameters', async function () {
    assert.equal((await contract.tokenCapacity()).toNumber(), tokenCapacity);
    
    const beginning = (await contract.beginning()).toNumber();
    const ending = (await contract.ending()).toNumber();

    assert.equal(beginning + lockPeriod * 86400, ending);
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
    await advanceTimeAndBlock((lockPeriod * 86400) + 1);
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
    await advanceTimeAndBlock((lockPeriod * 86400) + 1);
    await assertRevert(contract.lock(0, {
      from: accounts[0],
      value: web3.toWei(1, 'ether'),
    }));
  });

  it('should fail to lock with an invalid lock length', async function () {
    await assertRevert(contract.lock(1, {
      from: accounts[0],
      value: web3.toWei(1, 'ether'),
    }));
  });

  it('should lock 1 eth', async function () {
    await contract.lock(THREE_MONTHS, {
      from: accounts[0],
      value: web3.toWei(1, 'ether'),
    });

    const logs = await watchEvent(contract, { event: 'Deposit' });
    assert.equal(logs[0].args.sender, accounts[0]);
    assert.equal(logs[0].args.value.toNumber(), web3.toWei(1, 'ether'));
  });

  it('should unlock 1 eth', async function () {
    const wayBeforeBalance = (await getBalance(accounts[0])).toNumber();

    await contract.lock(THREE_MONTHS, {
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