require('dotenv').config();
const program = require('commander');
const Web3 = require('web3');
const fs = require('fs');
const EthereumTx = require('ethereumjs-tx');

const LOCKDROP_TESTNET_ADDRESS = "0x87c5eddf5b6d4b358b10c64bd71352ad566e7f10";
const LOCKDROP_JSON = JSON.parse(fs.readFileSync('./build/contracts/LockDrop.json').toString());
const ETH_PRIVATE_KEY = process.env.ETH_PRIVATE_KEY;

const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const contract = new web3.eth.Contract(LOCKDROP_JSON.abi, LOCKDROP_TESTNET_ADDRESS);

program
  .version('0.1.0')
  .option('-l, --lockers', 'lockers')
  .option('-b, --balance', 'balance')
  .option('-d, --deposit', 'deposit')
  .option('--lockLength', 'lockLength')
  .option('--lockValue', 'lockValue')
  .parse(process.argv);

const getLockDropLockers = () => {
  console.log('Fetching LockDrop lockers with minted balance amounts');
  contract.methods.getAllParticipants().call()
  .then(async participants => {
    let results = participants.map(async p => {
      return await contract.methods.getLocksForParticipant(p).call();
    });

    results = await Promise.all(results);

    let balanceSheet = {};
    results.forEach(result => {
      result['0'].forEach((pub, inx) => {
        if (pub in balanceSheet) {
          balanceSheet[pub] += result['1'][inx];
        } else {
          balanceSheet[pub] = result['1'][inx];
        }
      });
    });

    let genesisConfigBalances = [];
    for (key in balanceSheet) {
      genesisConfigBalances.push([key, balanceSheet[key]]);
    }

    console.log(genesisConfigBalances);
  });
};

const depositIntoLockDrop = (length, value) => {
    if (!length || !value) return new Error('Please input a length and value using --lockLength and --lockValue');
    console.log(`Depositing ${amount} into LockDrop contract for ${length} days`);
    web3.eth.getTransactionCount(account, function (err, nonce) {
      var data = contract.methods.lock(length);
      var tx = new EthereumTx({
        nonce: nonce,
        gasPrice: web3.utils.toHex(web3.utils.toWei('20', 'gwei')),
        gasLimit: 200000,
        to: contract.options.address,
        value: value,
        data: data,
      });

      tx.sign(ETH_PRIVATE_KEY);

      var raw = '0x' + tx.serialize().toString('hex');
      web3.eth.sendRawTransaction(raw, function (err, transactionHash) {
        console.log(`Sent tx with hash: ${transactionHash}`);
      });
    });
}

const getLockDropBalance = () => {
  console.log('Fetching LockDrop balance');
  web3.eth.getBalance(contract.options.address)
  .then(console.log);
};


console.log('you ordered a pizza with: Locks and drops');
if (program.lockers) getLockDropLockers();
if (program.balance) getLockDropBalance();
if (program.deposit) depositIntoLockDrop(program.lockLength, program.lockAmount);

