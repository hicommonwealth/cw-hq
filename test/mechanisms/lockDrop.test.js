import Promise from 'bluebird';
import assertRevert from '../../helpers/assertRevert';
import decodeLogs from '../../helpers/decodeLogs';

const LockDrop = artifacts.require("./LockDrop.sol");

contract('LockDrop', (accounts) => {
  let contract;
  let capacity = 1e18;
  let timeLength = 1;

  beforeEach(async () => {
    contract = await LockDrop.new(timeLength, capacity);
  });

  it('should initialize with the correct parameters', async function () {
    assert.isEqual(await contract.lockDropCapacity.call(), capacity);
  });
});