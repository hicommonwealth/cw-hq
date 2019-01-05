import Promise from 'bluebird';

export const advanceTimeAndBlock = async (time) => {
    await advanceTime(time);
    await advanceBlock();

    return getCurrentBlock();
};

export const advanceTime = (time) => {
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: "2.0",
            method: "evm_increaseTime",
            params: [time],
            id: new Date().getTime()
        }, (err, result) => {
            if (err) { return reject(err); }
            return resolve(result);
        });
    });
};

export const advanceBlock = () => {
    return new Promise((resolve, reject) => {
        web3.currentProvider.send({
            jsonrpc: "2.0",
            method: "evm_mine",
            id: new Date().getTime()
        }, (err, result) => {
            if (err) { return reject(err); }
            web3.eth.getBlock("latest", function (err, res) {
              if (err) reject(err);
              resolve(res.hash);
            });
        });
    });
};

export function getCurrentBlock() {
  return new Promise((resolve, reject) => {
    web3.eth.getBlock("latest", function (err, res) {
      if (err) return reject(err);
      resolve(res);
    });
  });
}

export async function getCurrentTimestamp() {
  const block = await getCurrentBlock();
  return block.timestamp;
}
