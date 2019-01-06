const { toBN, soliditySha3 } = require("web3").utils;

async function getLockDropDeposits(contract) {
  const deposits = {};
  const depositEvents = await contract.getPastEvents("Deposit", {
    fromBlock: 0,
    toBlock: "latest"
  });

  depositEvents.forEach((event) => {
    const data = event.returnValues;
    const key = soliditySha3(data.sender, data.lockIndex);
    deposits[key] = {
      sender: data.sender,
      receiver: data.receiver,
      numOfTokens: data.numOfTokens
    };
  });

  const unlockEvents = await contract.getPastEvents("Unlock", {
    fromBlock: 0,
    toBlock: "latest"
  });

  unlockEvents.forEach((event) => {
    const data = event.returnValues;
    deposits[soliditySha3(data.sender, data.lockIndex)].numOfTokens = "0";
  });

  const receivers = {};
  Object.keys(deposits).forEach((key) => {
    const receiver = deposits[key].receiver;

    let currentAmount = receivers[receiver];
    if (!currentAmount) {
      currentAmount = "0";
    }
    const amount = toBN(deposits[key].numOfTokens).add(toBN(currentAmount)).toString();
    if (amount !== "0") {
      receivers[receiver] = amount;
    }
  });

  const genesisConfigBalances = Object.keys(receivers).map((key) => [key, receivers[key]]);
  return [receivers, genesisConfigBalances];
}

module.exports = getLockDropDeposits;
