import Promise from 'bluebird';
import assertRevert from '../../helpers/assertRevert';
import decodeLogs from '../../helpers/decodeLogs';

const IdentityCouncil = artifacts.require("./IdentityCouncil.sol");

contract('IdentityCouncil', (accounts) => {
  let contract;
  let sybilAmt = 1;
  let quorumPt = 50;
  let trustedI = [];

  const getBalance = (address) => new Promise((resolve, reject) => {
    web3.eth.getBalance(address, (err, res) => {
      if (err) reject(err);
      else resolve(res.toNumber());
    })
  })

  beforeEach(async () => {
    contract = await IdentityCouncil.new();
  });

  it('should not be initialized before initialize', async function () {
    assert.isFalse(await contract.initialized());
  });

  it('should be initialized after initialize', async function () {
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    assert.isTrue(await contract.initialized());
  });

  it('should fail to initialize twice', async function () {
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await assertRevert(contract.initialize(sybilAmt, quorumPt, trustedI));
    assert.isTrue(await contract.initialized());
  });

  it('should fail to initialize with zerod quorum perecentage', async function() {
    await assertRevert(contract.initialize(sybilAmt, 0, trustedI));
  });

  it('should fail to initialize with any zerod trusted identities', async function() {
    await assertRevert(contract.initialize(sybilAmt, 0, [0]));
  });

  it('should have no council members before initialization', async function () {
    assert.equal((await contract.getCouncilSize()).toNumber(), 0);
  });

  it('should have only 1 council after initialization and proper parameters', async function () {
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    assert.equal((await contract.getCouncilSize()).toNumber(), 1);
    assert.equal((await contract.sybilResistantThresholdValue()).toNumber(), sybilAmt);
    assert.equal((await contract.quorumThreshold()).toNumber(), quorumPt);
  });

  it('should have no repetitive council members', async function () {
    trustedI = [accounts[0], accounts[0], accounts[0]];
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    assert.equal((await contract.getCouncilSize()).toNumber(), 1);
    assert.equal((await contract.sybilResistantThresholdValue()).toNumber(), sybilAmt);
    assert.equal((await contract.quorumThreshold()).toNumber(), quorumPt);
  });

  it('should fail to create proposal without paying sybil fee', async function () {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await assertRevert(contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 0,
    }));
  });

  it('should fail to create a proposal with a zero valued address', async function () {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await assertRevert(contract.proposeCandidate(0, voteTypeAddition, {
      from: accounts[1],
      value: 1,
    }));
  });

  it('should fail to proposeCandidate the same candidate for addition', async function () {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await assertRevert(contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    }));
  });

  it('should fail to proposeCandidate the same candidate for addition then removal', async function () {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await assertRevert(contract.proposeCandidate(accounts[1], !voteTypeAddition, {
      from: accounts[1],
      value: 1,
    }));
  });

  it('should fail to proposeCandidate a non council member for removal', async function () {
    const voteTypeRemoval = false;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await assertRevert(contract.proposeCandidate(accounts[1], voteTypeRemoval, {
      from: accounts[1],
      value: 1,
    }));
  });

  it('should fail to proposeCandidate a council member for removal twice', async function() {
    const voteTypeRemoval = false;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await contract.proposeCandidate(accounts[0], voteTypeRemoval, {
      from: accounts[0],
      value: 1,
    });

    await assertRevert(contract.proposeCandidate(accounts[0], voteTypeRemoval, {
      from: accounts[0],
      value: 1,
    }));
  });

  it('should fail to proposeCandidate a council member for addition', async function() {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);

    await assertRevert(contract.proposeCandidate(accounts[0], voteTypeAddition, {
      from: accounts[0],
      value: 1,
    }));
  });

  it('should create a proposal with the exact sybil fee', async function() {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);

    const beforeBalance = await getBalance(contract.address);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 2,
    });

    const afterBalance = await getBalance(contract.address);
    assert.equal(afterBalance - beforeBalance, 1);
  });

  it('should fail to allow non-council members to vote on proposals', async function() {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await assertRevert(contract.voteOnCandidateProposal(1, { from: accounts[1] }));
  });

  it('should fail to vote on a proposal that is non-existant', async function () {
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await assertRevert(contract.voteOnCandidateProposal(1, { from: accounts[0] }));
  });

  it('should fail to vote on a closed (deleted) proposal twice from the same account', async function () {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await contract.voteOnCandidateProposal(1, { from: accounts[0] });
    await assertRevert(contract.voteOnCandidateProposal(1, { from: accounts[0] }));
  });

  it('should vote and add a new council member', async function() {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    assert.equal((await contract.getCouncilSize()).toNumber(), 1);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await contract.voteOnCandidateProposal(1, { from: accounts[0] });
    assert.equal((await contract.getCouncilSize()).toNumber(), 2);
  });

  it('should fail to vote on adding existing council members', async function () {
    const trustedIds = [accounts[1]];

    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedIds);
    assert.equal((await contract.getCouncilSize()).toNumber(), 2);
    await assertRevert(contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    }));
  });

  it('should fail to vote on an open proposal twice from the same account', async function () {
    const trustedIds = [accounts[1], accounts[2], accounts[3]];

    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedIds);
    assert.equal((await contract.getCouncilSize()).toNumber(), 4);
    await contract.proposeCandidate(accounts[4], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await contract.voteOnCandidateProposal(1, { from: accounts[0] });
    assert.equal((await contract.getCouncilSize()).toNumber(), 4);

    await assertRevert(contract.voteOnCandidateProposal(1, { from: accounts[0] }));
  });

  it('should remove a council member', async function () {
    const voteTypeAddition = true;
    await contract.initialize(sybilAmt, quorumPt, trustedI);
    assert.equal((await contract.getCouncilSize()).toNumber(), 1);
    await contract.proposeCandidate(accounts[1], voteTypeAddition, {
      from: accounts[1],
      value: 1,
    });

    await contract.voteOnCandidateProposal(1, { from: accounts[0] });
    assert.equal((await contract.getCouncilSize()).toNumber(), 2);

    const voteTypeRemoval = false;
    await contract.proposeCandidate(accounts[1], voteTypeRemoval, {
      from: accounts[0],
      value: 1,
    });

    await contract.voteOnCandidateProposal(2, { from: accounts[0] });
    assert.equal((await contract.getCouncilSize()).toNumber(), 1);
  });
});