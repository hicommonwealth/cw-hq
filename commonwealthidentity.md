# Commonwealth Identity
## Abstract

Pseudo-anonymous addresses are a stop gap solution for user interaction with protocols. We outline our approach to working with an existing community of widely used standards, including ERC725. This includes a standard format for defining claims, a community governed root authority that curates a registry of of ERC725 identities, and an API and user interface for managing issued claims. These tools can be used by finance, governance, and security token protocols to tie identity claims to a pseudo-anonymous address.

## Introduction

Today, the lack of a user-friendly, widely adopted identity is a bottleneck for many protocols and voting systems. Most pertinent to governance, we need this to be resistant to Sybil-like attacks. We expect a standard, like email, to emerge for "logging in" to blockchain applications. Ideally this solution is self-sovereign. That is, an identity that is portable across different dApps, does not depend on any government and can never be taken away. We detail extensions and clarifications to one leading standard, ERC725. This consist of:

- **Standard Claims** - ****a specification for standard claims issuance that adheres to the ERC725 standard. These can be either on-chain, or verified off-chain between a requester and holder of an identity.
- **Identity Council -** a self-updating smart contract which a registry of approved issuers of standard ERC725 claims.
- **TCR-Based** **Claim Issuers  -** a TCR can be used to decentralize claims issuance. This may be useful to gain entry into a group that curates membership with a TCR-perhaps a religious group, citizenship test, or a technocratic council.
- **Management Interface: API and User Interface -** a user interface that connects to an Ethereum node and shows the set of approved credential issuers, a searchable index of claims they have issued, and an index of users which have requested or received claims.

After detailing the above, we discuss different use cases of this platform by protocols.

## Contract Interface

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

## **Standard Claims**

ERC725 doesn't specify any claim structure. To remedy this, we specify a format for public and private claims.

**Public Claims**

Claims in public that may be read directly on chain are denoted with the following field `claim.scheme = 10000.` This means data can be read directly by anyone and is useful for finance and insurance protocols

- Each claim takes the form of `{name: bytes[]}`
- We define the "basic identity claim" as one containing basic information about how one would like to identify themselves, which is not subject to public identification. The "basic identity claim" shall take the form of: `{name: ___, avatar: ___}`
- We define the "social attestation claim" as one containing data about one's identity as recognized by a public attestor. Shall take the form of: `{service: 'facebook', id: ___, name: ___}` (or similar)

**Private Claims**

There are cases in which the data for claims are necessary, but need to be verified off-chain. In this case the field `claim.scheme = 10001` means data is `{uint8 signature_length, bytes signature, bytes32 key}`

- Holder of the identity can present unencrypted version of `data` off-chain, and the recipient can verify that the `data` presented was signed by `key`, and that `key` is a valid claim-signing key in this ERC725 identity.
- An example claim of this form may be a "private financial identity claim" as one that contains data about one's private identity as it may be used in governance of financial applications. Shall take the form of: (TBD)

## The Identity Council

While we have defined a standard claims issuance, the set of claims that may be useful to a set of protocols still remains undefined. The Identity Council acts as a root authority to curate other claims issuers for this purpose. This is analogous to the trusted certificate store that ships with browsers. These issuers are trusted third parties, hereafter referred to as a TTP. 

Within this Council, Commonwealth will be the initial stakeholder. Functioning as a DAO, this organization will allow stakeholders in the Identity Council to propose and vote on potential additions and deletions of TTP claims issuers. 

    **DAO Mechanics for the Identity Council
    - A set of 'n' Issuers are each holders of a vote token.
    - A majority (>50%) is required to add a credential issuer.
    - A supermajority (>60%) is required to remove a credential issuer.**

Beyond the existing DAO mechanics, the public may propose additions to the list of TTP claims issuers. This is done by structuring a curation market (TCR) that allows any individual or organization the ability to propose a credential issuer. After the specified submission voting period, any credential issuer that has been accepted onto the TCR is automatically added to the Identity Council. 

In the long term, the set of TTP issuers within the Council may grow substantially. In this case, the Council may vote to create Sub-Councils that are delegated authority to issue particular classes of identity. For example, DeFi, an alliance of open finance protocols, may be delegated authority to whitelist open finance-related claims such as credit-scores.

While this system itself may not involve many privacy enhancing technologies past private voting, it should provide transparency to the evolution of verified credential issuers in the Commonwealth Protocol that are responsible for issuing public or private claims on identities following ERC725 and ERC735 standards. 

## TCR-Based **Claim Issuer**

The previous sections have discussed what individual claims come to mean and who forms the set of suitable claim issuers. Now, we detail the case in which a claim issuer is itself a decentralized authority, a TCR. Users who successfully pass the submission (and potential challenge) process of a TCR can thereafter submit the inclusion in the TCR as a claim to other protocols. 

For example, there is no way for a user to prove they have an external social media account unless the social media services issued a credential on their behalf. However, we can bootstrap the issuance of such a credential with a token curated registry (TCR) with the eventual Commonwealth Token. The process works by requiring identities to submit claims over external social media identities in the TCR. 

Upon inclusion in the TCR, the user is able to anonymously interact with any contract that wants to use the membership set provided by this TCR. The process is as follows.

1. The user generates randomness for use as a secret.
2. They send a hashed secret to the contract. This is used to build an incremental merkle tree for proving membership. 
3. The contract checks `msg.sender` to ensure that they have only submitted one secret to the contract ensuring that `msg.sender` can only vote or interact with the contract one. 

Constructions exist so that the membership set of the TCR can be reused in multiple merkle trees. This allows for multiple anonymous interactions, such as votes. Futhermore, claims issuers themselves be anonymous, constructions may come in the form of rings or ZKPs. We again defer discussion of such constructions to further papers. 

## Commonwealth Services

Blockchain identities are hard to use. The process of creating a self-sovereign blockchain identity is confusing and highly technical (it requires deploying custom smart contracts). It is also harder than it needs to be for developers to integrate identities into their app.

We have implemented two services to make using blockchain identity easier:

**Identity API**

- The Identity API is a free service, similar to Infura, for fetching a complete set of identity information about any Ethereum address. A developer can query it from the backend (or a user can query it from the browser) to retrieve any or all information from a range of identity services, including ERC725 self-sovereign identities, ERC780 identity registry data, and data on protocols like Bloom.
- We imagine this will be useful for services like Dharma relayers, where users interact with many other parties on the blockchain that are usually only identified by their address. A relayer can simply plug in a call to the Identity API, and immediately see human-readable names and social verifications next to each Ethereum address.

**Identity Management Dashboard**

- The Identity Management Dashboard is an interface for users to create their blockchain identity, and attach or revoke data connected to it.
- From the dashboard, a user can create an ERC725 identity, and attach a name, bio, and/or avatar to it. They will also be able to link Facebook, Github, and other social accounts, and access more advanced attestations like verifying citizenship or KYC status.
- When creating an ERC725, we also create an [username].commonw.eth. This allows individuals to utilize an existing namespace, and create a human-readable way for protocols to interact with each ERC725 identity. Additionally, this allows users an easy way with which to be sent any tokens. We maintain a registry of these linked ERC725 identities.
- We imagine this will be useful for relayers nudging their users to populate their blockchain identities. When logged into the Dharma relayer mentioned earlier, users without a blockchain identity should be prompted to create one using the Identity Management Dashboard. More examples are detailed below.

## Applications

Once an Ethereum identity or claim has been linked to an address, protocols are able to use them. To allow for non-collateralized loans, debt underwriters and creditors need to be able to verify the identity of individual debtors. For transparent and compliant security token transfers, security tokens (and issuers) need to tie KYC/AML claims to an identity. Certain voting schemes need a stable set of voters to ensure sybil resistant results which can be provided by an identity solution. 

**Lending or Insurance Protocols**

Protocols such as these carry counter-party risk. As such, any information on the debtor or purchaser of an insurance policy is needed by underwriters and creditors to price risk. This is especially true when any debtor or purchaser does not provide any collateral. Many classes of financial products function in this manner. 

By plugging into our API, protocols can look at public identities for individuals. One such example is Dharma, a protocol for decentralized debt issuance. This example assumes familiarity with the current protocol. Now: 

1. Dharma relayers can now offer real-identity loans (as opposed to pseudonymous loans)
2. Relayers and creditors can click through to see a identity/reputation history (how many loans they’ve offered/repaid, whether they’ve connected a Facebook, Twitter, etc.), as well as specify the type section of loans that they want to give. 
3. Real-world public reputation will become a positive signal. Good Dharma loans will be requested by people with real reputation, whereas non-collateralized loans to arbitrary addresses will have much higher default rates.

**Security Token Platforms** 

Security tokens tie off-chain cash flows to on-chain ownership certificates. These cash flows may be from an individual artwork, corporations, real estate and more. While the benefits of tokenizing an asset on the blockchain are numerous, a notable benefit is instant liquidity. However, each security token needs to comply with different requirements based on the purchaser's jurisdiction. Abacus, Securitize, Polymath, Harbor, and Otis act as security token issuers. As such these platforms can benefit from privately attested claims to comply with token transfer restrictions well as provide governance and voting rights to individuals on the blockchain.When security token governance is formalized on-chain, It means having a truly open API, as opposed to a closed gated API. Different individuals and different organizations (DAOs) may be able to participate through votes through a unified dashboard.

**Work Tokens and Protocols**

A large majority of protocols have mechanics that can be described as work protocols. That is, tokens that accrue value not to shareholders, but to those who actually participate in the running of the network. In work token systems such as Livepeer, Keep, and Tezos, a method for passive-holders to delegate their token to an individual exists. In this way, passive stakeholders are able put their stake towards use for another delegator. In exchange for a separate worker running hardware or other infrastructure. By plugging into an identity standard, we can provide rich data on workers and other protocol actors. This includes allowing:

- **Delegators choose between different workers.** While protocols may define some "in-protocol" reputation, data beyond historical slashing rate are often necessary. For example, one may ask if this address/identity has a history of using money for protocol improvements?
- **Verification of staking to the correct identity.** Right now, the standard campaign process for staking token with a worker can be a bit annoying. On one site, an individual may campaign for voters and link to a different address than what is stated, the result is funds that are sent to the wrong address. At the worst, a malicious worker may purposely slash it's own stake. Our API should verify that the address one is sending to is, for example, owned by the same person

**Governance and Social Networks**

Every protocol needs governance. Governance allows networks to make decisions and often involve user interactions. Interactions may include voting (and delegation of votes), staking (and delegation of stake), or airdropping tokens to new users. Having a queryable API makes all of these interactions more simple. Use cases are listed below.

- **Token distribution for new chains and TCRs.** When launching a new chain (perhaps with Substrate) or creating a TCR, the initial distribution of token is incredibly important determining how a network grow. A common assumption is the security model of these protocols is that at least 50% of tokenholders acts honestly. Distribution based on a set of claims/identity was recently utilized by the Handshake Protocol. To seed a new root DNS authority, they distributed tokens to open-source developers. However, this was done by a centralized authority. By querying the standard API above, a new team is able to airdrop token to the correct set of individuals without needing a central authority. For example, these projects can distribute token to only those who have attested to their Github identity using a decentralized claims Issuance TCR.
- **Running incentivized RFCs and straw polls.** To come to a decision for a new standard, we circulate RFCs to the community. Yet now, the community has the (happy) problem of having too much development activity. We have an overwhelming amount of proposals from which to make a decision. By utilizing a market-based mechanism for attention, a community may be able to circulate RFCs and come to consensus on a standard more quickly. By querying the API, an author of an RFC is able to post a bounty to someone or a set of individuals who needs to answer some question. These bounties can be addressed to one specific ERC725 identity. Alternatively they may choose to send a bounty to individuals that fulfill some claim requirement, such as the amount of token held that has been provided by an anonymous claims construction.
- **Secure voting systems.** A pre-requisite to building a system for liquid democracy or quadratic voting is an implementation of an identity and claims standard. We need a sybil-resistant identity scheme, beyond pseudo-anonymous addresses to facilitate quadratic voting. Additionally, to allow for well-informed decisions for staking on liquid democracies, we need to be able to capture information on individual voting history. By querying the API, an individual may see claims on how another individual has voted, allowing them to make an educated decision on with whom to stake their vote. For a quadratic voting scheme, a stable identity and claims scheme allows votes to be restricted to a set of verified citizens or claim holders.

## Conclusion

Relying on pseudo-anonymous addresses does not address issues facing protocols today. For example, debt issuers need identity to provide non-collateralized loans and security tokens need to tie KYC/AML claims to remain compliant. By building on an open standard,  this paper has outlined a standard specification for claims, a specification for a community-governed issuer of ERC725 identities, a method for decentralized claims issuance, and a queryable API. All these can be used by protocols to tie identity claims to pseudo-anonymous address. 

## References

- [https://github.com/OriginProtocol/identity-playground/blob/master/README.md](https://github.com/OriginProtocol/identity-playground/blob/master/README.md)
- [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md) (ERC72)
- [https://github.com/ethereum/EIPs/issues/735](https://github.com/ethereum/EIPs/issues/735) (ERC735)
- [https://github.com/hicommonwealth/identity-tcr](https://github.com/hicommonwealth/identity-tcr) (Decentralized Claims Issuer)
- [https://medium.com/set-protocol/announcing-defi-an-alliance-of-decentralized-finance-platforms-f9ac78c39fba](https://medium.com/set-protocol/announcing-defi-an-alliance-of-decentralized-finance-platforms-f9ac78c39fba) (DeFi)
- [https://thecontrol.co/understanding-decentralized-identity-433abb343279](https://thecontrol.co/understanding-decentralized-identity-433abb343279) (Why Decentralized Identity)
- ERC725 Registry???
