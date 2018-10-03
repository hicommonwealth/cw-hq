import Promise from 'bluebird';
import assertRevert from '../helpers/assertRevert';
import decodeLogs from '../helpers/decodeLogs';

const LockDrop = artifacts.require("./LockDrop.sol");

contract('LockDrop', (accounts) => {
  let contract;

  beforeEach(async () => {
    contract = await LockDrop.new();
  });
});