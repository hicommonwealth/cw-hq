const EdgewareERC20 = artifacts.require("./EdgewareERC20.sol");
const LockDrop = artifacts.require("./LockDrop.sol");

let lockPeriod = 3;
let tokenCapacity = 1e27;
let initialValuation = 1e16;
let priceFloor = 1

module.exports = function(deployer, network, accounts) {
  deployer.deploy(LockDrop, lockPeriod, tokenCapacity, initialValuation, priceFloor)
//  .then(async contract => {
//    async function lock(account, pubKey) {
//      await contract.lock(91, pubKey, {
//        from: account,
//        value: web3.toWei(1, 'ether'),
//      });
//    }

//    const pubKeys = [...Array(10)].map((i,x) => web3.fromAscii(`pubkey: ${x}`));
//    const results = pubKeys.map(async (key, inx) => {
//      return await lock(accounts[inx], key);
//    });

//    await Promise.all(results);
//  });
};
