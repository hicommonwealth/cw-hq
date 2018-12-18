import Promise from 'bluebird';

export const getBalance = (account) => {
  return new Promise((resolve, reject) => {
    web3.eth.getBalance(account, (err, res) => {
      if (err) reject(err);
      else resolve(res);
    });
  });
};
