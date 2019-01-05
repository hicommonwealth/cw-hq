require('dotenv').config();
const program = require('commander');
const Web3 = require('web3');
const fs = require('fs');
const getLockDropDeposits = require("../helpers/lockDropLogParser.js");

const LOCKDROP_TESTNET_ADDRESS = "0x345ca3e014aaf5dca488057592ee47305d9b3e10";
const LOCKDROP_JSON = JSON.parse(fs.readFileSync('./build/contracts/LockDrop.json').toString());
const ETH_PRIVATE_KEY = process.env.ETH_PRIVATE_KEY;

const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:9545"));
const contract = new web3.eth.Contract(LOCKDROP_JSON.abi, LOCKDROP_TESTNET_ADDRESS);

program
  .version('0.1.0')
  .option('-l, --lockers', 'lockers')
  .option('-b, --balance', 'balance')
  .option('-d, --deposit', 'deposit')
  .option('-u, --unlock', 'unlock')
  .option('-w, --withdraw', 'withdraw')
  .option('--ending', 'ending')
  .option('--lockLength', 'lockLength')
  .option('--lockValue', 'lockValue')
  .option('--pubKey', 'pubKey')
  .option('--lockIndex', 'lockIndex')
  .parse(process.argv);

async function getCurrentTimestamp() {
  const block = await web3.eth.getBlock("latest");
  return block.timestamp;
}

async function getFormattedLockDropLockers() {
  console.log('Fetching LockDrop locked deposits...');
  console.log("");
  const [_, genesisConfigBalances] = await getLockDropDeposits(contract);
  console.log(genesisConfigBalances);
};

async function depositIntoLockDrop(length, value, pubKey) {
    console.log(`Depositing ${value} into LockDrop contract for ${length} days. Receiver: ${pubKey}`);
    console.log("");
    const coinbase = await web3.eth.getCoinbase();
    const data = contract.methods.lock(length, pubKey).encodeABI();
    const tx = await web3.eth.sendTransaction({
      from: coinbase,
      to: LOCKDROP_TESTNET_ADDRESS,
      gas: 150000,
      value,
      data
    });
    console.log(`Transaction send: ${tx.transactionHash}`);
}

async function unlockDeposit(index) {
  const coinbase = await web3.eth.getCoinbase();
  console.log(`Unlocking deposit for account: ${coinbase} at index: ${index}`);
  console.log("");
  const data = contract.methods.unlock(index).encodeABI();
  const tx = await web3.eth.sendTransaction({
    from: coinbase,
    to: LOCKDROP_TESTNET_ADDRESS,
    gas: 100000,
    data
  });
  console.log(`Transaction send: ${tx.transactionHash}`);
}

async function withdrawDeposit() {
  const coinbase = await web3.eth.getCoinbase();
  console.log(`Withdrawing deposit for account: ${coinbase}`);
  console.log("");
  const data = contract.methods.withdraw().encodeABI();
  try {
    const tx = await web3.eth.sendTransaction({
      from: coinbase,
      to: LOCKDROP_TESTNET_ADDRESS,
      gas: 100000,
      data
    });
    console.log(`Transaction send: ${tx.transactionHash}`);
  } catch(e) {
    console.log(e);
  }
}

async function getLockDropBalance() {
  console.log('Fetching LockDrop balance...');
  console.log("");
  const res = await web3.eth.getBalance(contract.options.address);
  console.log(res);
};

async function getEnding() {
  const coinbase = await web3.eth.getCoinbase();
  const ending = await contract.methods.ending().call({from: coinbase});
  const now = await getCurrentTimestamp();
  console.log(`Ending in ${(ending - now) / 60} minutes`);
}

console.log("");
console.log('You ordered a pizza with: Locks and drops');
console.log("");

if (program.lockers) getFormattedLockDropLockers();

if (program.balance) getLockDropBalance();

if (program.deposit) {
  if (!program.lockLength || !program.lockValue || !program.pubKey) {
    throw new Error('Please input a length and value using --lockLength, --lockValue and --pubKey');
  }
  depositIntoLockDrop(...program.args);
}

if (program.unlock) {
  if (!program.lockIndex) {
    throw new Error('Please specify lock index using --lockIndex');
  }
  unlockDeposit(...program.args);
}

if (program.withdraw) withdrawDeposit();

if (program.ending) getEnding();
