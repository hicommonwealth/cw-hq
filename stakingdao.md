# Staking DAO
## Background

---

If we're going to have a world where coordination happens mainly in DAOs and protocols, then we need to actually have experiments where these actually are in product

## Why?

---

Each Transcoder DAO Token is

- A claim on the cash flow
- A voting right for what the params should be.

This token becomes a tradable ERC20 Token. Other people who do not want to participate in this DAO are still free to delegate stake to DAO. They are free to withdraw their token, without any restrictions. The downside is that they do not have an asset that is liquid, the tradeable ERC20 Token. On top of this token, people can now create derivatives products, bonds, that are rights to cash flows. 

This is an early experiment for larger DAOs. This is repeatable.

## Requirements

---

- Mint at vote token at a one-to-one ratio in exchange for staked token.
- Vote on `msg.sender` who is actually running the transcoder, allow him to have more tokens.
- using PLCR vote to sets params for:
  - `fee`
  - `reward`
- using PLCR, vote on funds directly owned by this DAO
  - reinvested, any used for staking (this is the default)
  - gracefully dies, when there are no LPT staked within it anymore
  - Burn vote token to unbond, and call withdraw after the right time period.

# **Current Limitation**

---

- The only limitation for the protocol that we are build for (Livepeer) is that the protocol does not allow withdraws to a cold wallet/smart contract address this is something that Doug and co are working on.
- Funds will be withdrawn every single week, and moved to the this fund wallet, where individuals can then vote to direct funds towards

# Questions

---

- Key management
- Returning tokens that are not of the specified delegated token type
  - I.e. return any 0x token that might have been set to this contract address.
- Lock the underlying collateral, the set of LPT that people have added to only allow for staking with the Livepeer Staking contract
  - Hardcode this address in and add a modifier before committing to a function call.

# Future Work

---

There are many different experiments to be run. Our approach is again to build to spec/specific use case and generalize from there.

For this specific transcoding DAO changes can be made that...

- Allow you to spin up a transcoding DAO for a different work token
- Change the different voting implementation
- Follow a different curve for minting and burning tokens
  - This may be necessary because we want to get into the active set, so more DAO Tokens are minted at a faster rate for early individuals before minting at a slower one-to-one rate.

We would like to work on multiple DAOs that work on these different experiments.

Additionally, different DAOs can be created within one ecosystem for a different purpose. We quickly detail them below. Again, these are DAOs that should be able to be created and reused across different applications.

- **Diversified Transcoding DAO for Delegators.** Instead of directly staking with one transcoder, a delegator may choose to delegate to this DAO instead that has a target return rate. The DAO may .
- **Transcoding DAO for Transcoders.** Multiple Transcoders redirects some portion of their earnings towards this DAO. Acts as a pool for setting fees/rewards on the network. Potentially can constrain the size of the largest DAOs.
- **Funding DAO.** DAO with voting rights on where to direct funds for development of a protocol. Within the Livepeer Protocol, there is a slashing pool, this may be an ideal place to allow to start. Perhaps we can mint vote tokens given to the active transcoder set in proportion

## References

---

- [https://research.aragon.org/t/staking-pool-daos/136](https://research.aragon.org/t/staking-pool-daos/136)
- [https://blog.aragon.org/aragon-labs-research-update-1/](https://blog.aragon.org/aragon-labs-research-update-1/)
- [https://research.aragon.org/t/key-hierarchy-for-staking-accounts/78](https://research.aragon.org/t/key-hierarchy-for-staking-accounts/78)
