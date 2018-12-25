const program = require('commander');
const Web3 = require('web3');
const fs = require('fs');

const LOCKDROP_TESTNET_ADDRESS = "0xf7faeb7cd6b8e5f035ed049d993883fa9dcc8862";
const LOCKDROP_JSON = JSON.parse(fs.readFileSync('./build/contracts/LockDrop.json').toString());

const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const contract = new web3.eth.Contract(LOCKDROP_JSON.abi, LOCKDROP_TESTNET_ADDRESS);

program
  .version('0.1.0')
  .option('-l, --lockers', 'lockers')
  .option('-b, --balance', 'balance')
  .parse(process.argv);

console.log('you ordered a pizza with: Locks and drops');
if (program.lockers) getLockDropLockers();
if (program.balance) getLockDropBalance();

const getLockDropLockers = () => {
    console.log('Fetching LockDrop lockers with minted balance amounts');
};

const getLockDropBalance = () => {
    console.log('Fetching LockDrop balance');
};
