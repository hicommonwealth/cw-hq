const EdgewareERC20 = artifacts.require("./EdgewareERC20.sol");
const LockDrop = artifacts.require("./LockDrop.sol");

let lockPeriod = 1;
let tokenCapacity = 1e27;
let initialValuation = 1e16;
let priceFloor = 1

module.exports = function(deployer) {
  deployer.deploy(LockDrop, lockPeriod, tokenCapacity, initialValuation, priceFloor);
};
