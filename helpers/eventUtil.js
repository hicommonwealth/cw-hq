import Promise from 'bluebird';

export const watchEvent = (contract, filter) => {
  return new Promise((resolve, reject) => {
    var event = contract[filter.event]();
    event.watch();
    event.get((error, logs) => {
      if (error) reject(error);
      else resolve(logs);
    });
    event.stopWatching();
  });
};
