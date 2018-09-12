# Commonwealth Identity Council
## Abstract

Pseudo-anonymous addresses are a stop gap solution for user interaction with protocols. We outline a several comments for a standardized identity platform. This includes a community governed root authority that curates a registry of of ERC725 identities, a standard credential contract interface, and an API and user interface for managing issued credentials. This platform can be used by finance, governance, and security token protocols to tie identity claims to a pseudo-anonymous address. This allows for rich user interaction between user and protocol.

## Introduction

To allow for non-collateralized loans, debt underwriters and creditors need to be able to verify the identity of individual debtors. Security tokens need to tie KYC/AML claims to remain compliant. Certain voting schemes need a stable set of voters to ensure sybil resistant results. These protocols are best served by an Identity Platform which consists of several components:

- **Identity Council -** a self-updating smart contract which a registry of approved issuers of ERC725 identities.
- **Standard Credentials: Contract Interface -** a shared specification for credentials issuance that implements ERC725 credential issuance.
- **Special** **Claim Issuer Types  -** claims issuers can use a TCR to decentralize claims approval. After approval, the claim submitter can use their inclusion in said TCR to vote or interact with other protocols.
- **Management Interface: API and User Interface -** a user interface that connects to an Ethereum node and shows the set of approved credential issuers, a searchable index of credentials they have issued, and an index of users which have requested or received credentials.

After detailing the above, we discuss different use cases of this platform by protocols.

## The Identity Council

The Identity Council acts as a root authority to curate other credential issuers. This is analogous to the trusted certificate store that ships with browsers. These issuers are trusted third parties, hereafter referred to as a TTP. Commonwealth will be the initial stakeholder in the process for adding new, verified credential issuers. Functioning as a DAO, this organization will allow stakeholders in the Identity Council to propose and vote on potential additions and deletions of TTP credential issuers. 

    **DAO Mechanics for the Identity Council
    - Issuers are 5 holders of a token (may only need one token).
    - A majority vote is required to add a credential issuer.
    - A supermajority (60%) is required to remove a credential issuer.**

Beyond the existing DAO mechanics, the public may propose and add to the list of TTP credential issuers. This is done by structuring a curation market (TCR) that allows any individual or organization the ability to propose a credential issuer. After the specified submission voting period, any credential issuer that has been accepted onto the TCR is automatically added to the Identity Council. 

In the long term, the set of TTP issuers within the Council may grow substantially. In this case, the Council may vote to create Sub-Councils that are delegated authority to issue particular classes of identity. For example, DeFi, an alliance of open finance protocols, may be delegated authority to whitelist open finance-related claims such as credit-scores.

While this system itself may not involve many privacy enhancing technologies past private voting, it should provide transparency to the evolution of verified credential issuers in the Commonwealth Protocol that are responsible for issuing public or private claims on identities following ERC725 and ERC735 standards. 

## **Standard Credentials**: Contract Interface

Adopted heavily from [Origin Protocol Implementation](https://github.com/OriginProtocol/origin-playground), we quickly present the ERC 725 and 735 standards.

- ***ERC725***

      pragma solidity ^0.4.22;
      
      contract ERC725 {
      
          uint256 constant MANAGEMENT_KEY = 1;
          uint256 constant ACTION_KEY = 2;
          uint256 constant CLAIM_SIGNER_KEY = 3;
          uint256 constant ENCRYPTION_KEY = 4;
      
          event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
          event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
          event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
          event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
          event Approved(uint256 indexed executionId, bool approved);
      
          struct Key {
              uint256 purpose; //e.g., MANAGEMENT_KEY = 1, ACTION_KEY = 2, etc.
              uint256 keyType; // e.g. 1 = ECDSA, 2 = RSA, etc.
              bytes32 key;
          }
      
          function getKey(bytes32 _key) public constant returns(uint256 purpose, uint256 keyType, bytes32 key);
          function getKeyPurpose(bytes32 _key) public constant returns(uint256 purpose);
          function getKeysByPurpose(uint256 _purpose) public constant returns(bytes32[] keys);
          function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool success);
          function execute(address _to, uint256 _value, bytes _data) public returns (uint256 executionId);
          function approve(uint256 _id, bool _approve) public returns (bool success);
      }

- ***ERC735***

      pragma solidity ^0.4.22;
      
      contract ERC735 {
      
          event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);    event ClaimAdded(bytes32 indexed claimId, uint256 indexed claimType, address indexed issuer, uint256 signatureType, bytes32 signature, bytes claim, string uri);
          event ClaimAdded(bytes32 indexed claimId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
          event ClaimRemoved(bytes32 indexed claimId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
          event ClaimChanged(bytes32 indexed claimId, uint256 indexed claimType, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
      
          struct Claim {
              uint256 claimType;
              uint256 scheme;
              address issuer; // msg.sender
              bytes signature; // this.address + claimType + data
              bytes data;
              string uri;
          }
      
          function getClaim(bytes32 _claimId) public constant returns(uint256 claimType, uint256 scheme, address issuer, bytes signature, bytes data, string uri);
          function getClaimIdsByType(uint256 _claimType) public constant returns(bytes32[] claimIds);
          function addClaim(uint256 _claimType, uint256 _scheme, address issuer, bytes _signature, bytes _data, string _uri) public returns (bytes32 claimRequestId);
          function removeClaim(bytes32 _claimId) public returns (bool success);
      }

- ***Keyholder***

      pragma solidity ^0.4.22;
      
      import './ERC725.sol';
      
      contract KeyHolder is ERC725, ERC735 {
      
          uint256 executionNonce;
      
          struct Execution {
              address to;
              uint256 value;
              bytes data;
              bool approved;
              bool executed;
          }
      
          mapping (bytes32 => Key) keys;
          mapping (uint256 => bytes32[]) keysByPurpose;
          mapping (uint256 => Execution) executions;
      
          event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);
      
          function removeKey(bytes32 _key) public returns (bool success);
          function keyHasPurpose(bytes32 _key, uint256 _purpose) public view returns(bool result);
      }

Now, we define a standard claims interface that adhere to the above interface.

- Each claim takes the form of `{name: bytes[]}`
- Claims in public that may be read directly on chain are denoted with the following field `claim.scheme = 10000.` This means data can be read directly by anyone and is useful for finance and insurance protocols
  - We define the "basic identity claim" as one containing basic information about how one would like to identify themselves, which is not subject to public identification. The "basic identity claim" shall take the form of: `{name: ___, avatar: ___}`
  - We define the "social attestation claim" as one containing data about one's identity as recognized by a public attestor. Shall take the form of: `{service: 'facebook', id: ___, name: ___}` (or similar)
- There are cases in which the data for claims are necessary, but need to be verified off-chain. In this case the field `claim.scheme = 10001` means data is `{uint8 signature_length, bytes signature, bytes32 key}`
  - Holder of the identity can present unencrypted version of `data` off-chain, and the recipient can verify that the `data` presented was signed by `key`, and that `key` is a valid claim-signing key in this ERC725 identity.
  - An example claim of this form may be a "private financial identity claim" as one that contains data about one's private identity as it may be used in governance of financial applications. Shall take the form of: (TBD)

## Special **Claim Issuer Types**

The previous sections have discussed who claim issuers are and what individual claims come to mean. Now, we detail the case in which a claim issuer is itself a decentralized authority. Users who successfully pass the submission (and potential challenge) process of a TCR can thereafter submit the inclusion in the TCR as a claim to other protocols.

Upon inclusion in the TCR, the user can now send a hashed secret to any contract wants to use the membership set of the TCR. The secret sent by the user is used to build an incremental merkle tree for proving membership. The contract checks `msg.sender` to ensure that they have only submitted one secret to the contract ensuring that `msg.sender` can only vote or interact with the contract one. Constructions exist so that the membership set of the TCR can be reused in multiple merkle trees. This allows for multiple interactions such as votes. 

For example, there is no way for a user to prove they have an external social media account unless the social media services issued a credential on their behalf. However, we can bootstrap the issuance of such a credential with a token curated registry (TCR) with the eventual Commonwealth Token. The process works by requiring identities to submit claims over external social media identities in the TCR. 

Now, we have designed a decentralized, market derived claims issuer in the form of a token curated registry that permits successful listings to be included in a cryptographic accumulator. This accumulator serves as the backbone of some of the privacy systems for claims issuance and voting to be discussed in a future paper. 

Claims issuers may come in the form of ring signature or ZKP. However, we leave discussion of such constructions to further papers.

## Commonwealth Identity API

Any network becomes more useful as more users adhere to the standard. To bootstrap usage, we propose several services built on top of the Identity Council and the Standard Credential Interface. This is 1) an API to query any Ethereum address and 2) an interface to manage your own ERC725 identity and claims.

[**commonwealth/api**](http://commonwealth.id/api)

[Commonwealth/api](http://commonwealth.id/api) is an API, similar to Infura, that provides information on an Ethereum address. In this way, Dharma relayers, and other services, can use it to retrieve identity information stored on the blockchain.

This API service takes any Ethereum address and resolves it to a human-readable name, while allowing the application provider to additionally retrieve off-chain data from trusted custodians. With the right permissions, you are able to make one API request to the endpoint and retrieve all the information on an ETH address or identity. 

- Information provided can include claims issued by the Commonwealth TCR, Bloom identities, Civic and other identities whether they are on-chain or off-chain. This may include queryable data provided by ERC725 identities, .
- In future work, we may add cross-chain query support specifically for identities and claims such as on Blockstack or Polkadot.

[**commonwealth.id/**](http://commonwealth.id/)

This is the management interface where you can see all your public keys, link social accounts, and request attestations from third parties including the Commonwealth Network and Identity Council. If an individual has not created an ERC725 identity, it is easy to do so. At [commonwealth.im](http://commonwealth.im/), a user can:

1. Create an account and sign a verification of that account.
2. Sign back into that account from Facebook, Twitter, Github, or Metamask. 
  - Optionally, a user is able to attach an email and password
3. From our website, a user is able to attach a bio to an identity, see all the services you’ve signed into, and revoke trusted-third-party data relay.
  - By plugging directly into Metamask/other existing wallets, we are able to see human-readable information beyond function calls and contract data. For example, we can see which loans Dharma loans have been issued to said address and identity.

## Applications

Once an Ethereum identity or claim has been linked to an address, protocols are able to use them. We detail several applications below.

**Lending or Insurance Protocols**

Protocols such as these carry counter-party risk. As such, any information on the debtor or purchaser of an insurance policy is needed by underwriters and creditors to price risk. This is especially true when any debtor or purchaser does not provide any collateral. Many classes of financial products function in this manner. 

By plugging into our API, protocols can look at public identities for individuals. One such example is Dharma, a protocol for decentralized debt issuance. This example assumes familiarity with the current protocol. Now: 

1. Dharma relayers can now offer real-identity loans (as opposed to pseudonymous loans)
2. Relayers and creditors can click through to see a identity/reputation history (how many loans they’ve offered/repaid, whether they’ve connected a Facebook, Twitter, etc.), as well as specify the type section of loans that they want to give. 
3. Real-world public reputation will become a positive signal. Good Dharma loans will be requested by people with real reputation, whereas non-collateralized loans to arbitrary addresses will have much higher default rates.

**Security Token Platforms** 

Security tokens tie off-chain cash flows to on-chain ownership certificates. These cash flows may be from art, corporations, real estate and more. While the benefits of tokenizing an asset on the blockchain are numerous, the most notable to this class of assets is instant liquidity. However, each security token needs to comply with different requirements based on the jurisdiction within which the purchaser is based. Abacus, Securitize, Polymath, Harbor, and Otis act as security token issuers. As such these platforms can benefit from privately attested credentials to comply with token transfer restrictions well as provide governance and voting rights to individuals on the blockchain.

When security token governance is formalized on-chain, It means having a truly open API, as opposed to a closed gated API. Different individuals and different organizations (DAOs) may be able to participate through votes through a unified dashboard.

**Work Tokens and Protocols**

A large majority of protocols have mechanics that can be described as work protocols. That is, tokens accrue not to shareholders, but to those who actually participate in the running of the network. In work token systems such as Livepeer, Keep, Vest, and Tezos, a method for passive-holders to delegate their token to an individual exists. In this way, passive stakeholders are able put their stake towards use without having to deal with hardware or real world infrastructure. By plugging into the identity standard, we can provide rich data on workers and other protocol actors. This includes allowing:

- Stakers to choose between different workers.
  - While protocols may define some "in-protocol" reputation, data beyond historical slashing rate are often necessary. For example, one may ask if this address/identity has a history of using money for protocol improvements?
- Verification of staking to the correct identity.
  - Right now, the standard campaign process for staking token with a worker can be a bit annoying. On one site, an individual may campaign for voters and link to a different address than what is stated, the result is funds that are sent to the wrong address. At the worst, a malicious worker may purposely slash it's own stake. Our API should verify that the address one is sending to is, for example, owned by the same person

**Governance and Social Networks**

Every protocol needs governance. Governance allows networks to make decisions and often involve user interactions. Interactions may include voting (and delegation of votes), staking (and delegation of stake), or airdropping tokens to new users. Having a queryable API makes all of these interactions more simple. Use cases are listed below.

- Token distribution for new chains and TCRs
  - When launching a new chain perhaps with Substrate or creating a TCR, the initial distribution of token is incredibly important in how networks grow. A recent example is Handshake's distribution of tokens to open-source developers, which seeded stakeholders who would use the service. By querying the API, a new team is able to airdrop token to the correct set of individuals. For example, these individuals have attested their Github identity using a Commonwealth Claims Issuance TCR.
- Running incentivized RFCs and straw polls
  - To come to a decision either for a new standard, often we circulate RFCs to the broader community. However, with the happy problem of too much development activity leads to a point where individuals that need their voices heard, are not able to dedicate time to reading through a proposal. By querying the API, an individual is able to post a bounty to someone or a set of individuals who needs to answer some question. These bounties can target one ERC725 identity, or a set of claims on the amount of token held by an identity as attested by an above claims construction.
- Staking vote
  - Implementations of liquid democracy, allowing individuals to stake their vote on separate issues with different individuals currently does not exist. However, a pre-requisite to building such a system is the implementation of an identity and claims standard that is able to capture information on individual voting history. By querying the API, an individual may see claims on how another individual has voted, allowing them to make an educated decision on with whom to stake their vote.

## Conclusion

Relying on pseudo-anonymous addresses does not address issues facing protocols today. For example, debt issuers need identity to provide non-collateralized loans and security tokens need to tie KYC/AML claims to remain compliant. By building on an open standard,  this paper outlines a specification for a community-governed issuer of ERC725 identities, which can be used by decentralized finance and governance protocols to tie identity claims to a formerly pseudo-anonymous address. 

## References

- [https://github.com/OriginProtocol/identity-playground/blob/master/README.md](https://github.com/OriginProtocol/identity-playground/blob/master/README.md)
- [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md)
- [https://github.com/ethereum/EIPs/issues/735](https://github.com/ethereum/EIPs/issues/735)
- Reference TCR spec
- Dharma reference
