# An Interoperable Blockchain Identity System

Commonwealth Labs

Dillon Chen (dillon@commonwealth.im), Drew Stone (drew@commonwealth.im), Raymond Zhong (raymond@commonwealth.im)

## Abstract [to edit]

Pseudo-anonymous addresses are a stop gap solution for user interaction with protocols. We outline our approach to working with an existing community of widely used standards, including ERC725. This includes a standard format for defining claims, a community governed root authority that curates a registry of of ERC725 identities, and an API and user interface for managing issued claims. These tools can be used by finance, governance, and security token protocols to tie identity claims to a pseudo-anonymous address.

## 1. Introduction: The need for an identity standard

On the Internet, email addresses have emerged as a de facto standard for user identity and authentication. They are universally interoperable and recognized across services. No such widely adopted identity system has emerged on the blockchain yet.

However, several areas of blockchain applications that have only recently been deployed in the real world benefit strongly from some form of persistent user identity:

- Lending and underwriting insurance are infeasibly risky unless the lender/underwriter knows the identity of their counterparty.
- Protocol governance is difficult to conduct if voters only know each other pseudonymously.
- Credit scoring, curation networks, and other social applications benefit if verifiable real names can be used on the blockchain.

Ideally, an identity standard would serve all of these use cases while having the ease of use and universal addressability of email login. It would support human-readable real names, as well  as provide sybil-resistance, i.e. verification that different identities are actually separate people in the real world.

## 2. Characteristics of existing identity standards

A large number of blockchain identity standards already exist. One list contains over 50 identity specifications authored by different groups [TODO: citation - Github repo]. In spite of (and perhaps because of) the large number of options, no single service has captured enough mindshare to be seen as a general standard, and wallets and key management services have avoided closely associating themselves with one either.

Additionally, many existing identity services are not naturally suited for general use across blockchain applications.

Some identity protocols are vertical-specific, like Sovrin (focusing on applications like real-name ID). Other identity systems are tightly coupled to applications controlled by a central provider, like Civic and uPort, or impose frictions, like Bloom, which requires users to stake Bloom Token before establishing an identity.

One could use email as a comparison again: most existing identity systems lack the simplicity and interoperability of email addresses, nor are they part of the neutral commons.

## 3. An identity system built on ERC725

The ERC725 standard is well positioned among the many identity systems that exist already to fulfill the role of a neutral identity service:

- **Simplicity**. The standard defines only essential interfaces like key management and making/verifying claims.
- **Neutrality**. Rather than being authored and edited by any one self-interested organization, the ERC725 spec was authored by an Ethereum developer and edited by the Ethereum community at large. Ethereum is the dominant smart contract and decentralized computing platform today, and it is likely to set standard for the decentralized compute platforms that emerge in the future.
- **Self-sovereignty**. Like email addresses, ERC725 identity isis self-sovereign. That is, an identity that is portable across different dApps, and does not depend on any governing organization and can never be taken away.
- **Ecosystem**. There is a strong ecosystem of decentralized applications, wallets, and other identity services that have affirmed their intent to build on ERC725.

It seems worth mentioning that the the ERC725 standard was proposed and finalized in late 2017, yet in over a year, no widely adopted implementation has emerged. While this could be a concern, we believe this isn’t unreasonable in a year where very few apps launched to mainnet.

Nevertheless, we do believe that ERC725 has several missing pieces that need to be built on top, which we will cover in this paper:

- **Smart contract code**: Borrowing heavily from existing implementations of ERC725, we have created an isolated set of smart contracts implementing the protocol.
- **Standard claims**: ERC725 defines the ability to make claims, but doesn’t specify the specific claims to be made. While this is acceptable and even beneficial for a _protocol_, it stops ERC725 from being a useful _product_. We define a set of standard claims on top of the ERC725 standard, including claims that are _on-chain_ or _verified off-chain_.
- **Common namespace**: Email has the property of being a common namespace. Using the root authority, we define a common namespace for blockchain identities that can be used similarly.
- **Root authority for identity claims (Identity Council)**: ERC725 specifies the ability to make verifiable claims, but doesn’t specify which claims issuers to trust. This holds back adoption because each user of ERC725 must set themselves up as claim issuance authorities, and cannot bootstrap off the reputation of an existing organization. We define a simple, upgradeable root authority on the blockchain to solve this problem.
- **Decentralized claims issuers**: Using the token-curated registry (TCR) model, we define a scheme for decentralized credential issuance. This serves as a useful example application of an identity system that can be built on top of our transitive Web of Trust enabled by the root authority.
- **User interfaces and developer tools**: We have developed a user interface to help new users set up their blockchain identity, and find services they can access using it.

## 3.1. The ERC725 standard and smart contracts

ERC 725 manages on-chain identity and stores associated public keys (on the Ethereum blockchain). The ERC725 identity contract contains a signature proving that the owner of the contract controls a particular claim to their identity, while the interface is specified, what a standard claim represents comes down to the implementation.

## 3.2. Standard claims

The ERC725 standard specifies a high-level outline of how to store claim data, but doesn’t specify the structure of claim content. We specify two sets of templates for claim content, so that applications interfacing with ERC725 can read each others’ claims.

### 3.2.1. Public claims

Claims in public that may be read directly on chain are denoted with the following field `claim.scheme = 10000.` This means data can be read directly by anyone and is useful for finance and insurance protocols

- Each claim takes the form of `{name: bytes[]}`
- We define the "basic identity claim" as one containing basic information about how one would like to identify themselves, which is not subject to public identification. The "basic identity claim" shall take the form of: `{name: ___, avatar: ___}`
- We define the "social attestation claim" as one containing data about one's identity as recognized by a public attestor. Shall take the form of: `{service: 'facebook', id: ___, name: ___}` (or similar)

### 3.2.2. Private claims

There are cases in which the data for claims are necessary, but need to be verified off-chain. In this case the field `claim.scheme = 10001` means data is `{uint8 signature_length, bytes signature, bytes32 key}`

- Holder of the identity can present unencrypted version of `data` off-chain, and the recipient can verify that the `data` presented was signed by `key`, and that `key` is a valid claim-signing key in this ERC725 identity.
- An example claim of this form may be a "private financial identity claim" as one that contains data about one's private identity as it may be used in governance of financial applications. Shall take the form of: (TBD)

## 3.3. Root authority (Identity Council)

While we have defined a standard claims issuance, the set of claims issuers that may be useful to a set of protocols still remains undefined. The Identity Council acts as a root authority to curate other claims issuers for this purpose. This is analogous to the trusted certificate store that ships with browsers. These issuers are trusted third parties, hereafter referred to as a TTP. 

Within this Council, Commonwealth will be among one of several community selected parties to curate issuers. Functioning as a DAO, this organization will allow stakeholders in the Identity Council to propose and vote on potential additions and deletions of TTP claims issuers. 

    **DAO Mechanics for the Identity Council
    - A set of 'n' Issuers are each holders of a vote token.
    - A majority (>50%) is required to add a credential issuer.
    - A supermajority (>60%) is required to remove a credential issuer.**

Beyond the existing DAO mechanics, the public may propose additions to the list of TTP claims issuers. This is done by structuring a curation market (TCR) that allows any individual or organization the ability to propose a credential issuer. After the specified submission voting period, any credential issuer that has been accepted onto the TCR is automatically added to the Identity Council. 

In the long term, the set of TTP issuers within the Council may grow substantially. In this case, the Council may vote to create Sub-Councils that are delegated authority to issue particular classes of identity. For example, DeFi, an alliance of open finance protocols, may be delegated authority to whitelist open finance-related claims such as credit-scores.

While this system itself may not involve many privacy enhancing technologies past private voting, it should provide transparency to the evolution of verified credential issuers in the Commonwealth Protocol that are responsible for issuing public or private claims on identities following ERC725 and ERC735 standards. 

## 3.4. Decentralized claim issuance (TCR-based claim issuer)

The previous sections have discussed what individual claims come to mean and who forms the set of suitable claim issuers. Now, we detail the case in which a claim issuer is itself a decentralized authority, a TCR. Users who successfully pass the submission (and potential challenge) process of a TCR can thereafter submit the inclusion in the TCR as a claim to other protocols. 

For example, there is no way for a user to prove they have an external social media account unless the social media services issued a credential on their behalf. However, we can bootstrap the issuance of such a credential with a token curated registry (TCR) with the eventual Commonwealth Token. The process works by requiring identities to submit claims over external social media identities in the TCR. 

Upon inclusion in the TCR, the user is able to anonymously interact with any contract that wants to use the membership set provided by this TCR. The process is as follows.

1. The user generates randomness for use as a secret.
2. They send a hashed secret to the contract. This is used to build an incremental merkle tree for proving membership. 
3. The contract checks `msg.sender` to ensure that they have only submitted one secret to the contract ensuring that `msg.sender` can only vote or interact with the contract one. 

Constructions exist so that the membership set of the TCR can be reused in multiple merkle trees. This allows for multiple anonymous interactions, such as votes. Futhermore, claims issuers themselves be anonymous, constructions may come in the form of rings or ZKPs. We again defer discussion of such constructions to further papers. 

## 3.5. User interfaces and developer tools

The process of creating a self-sovereign blockchain identity is confusing and highly technical. Additionally, it can be easier for developers to integrate blockchain identity into their app. We have implemented services to make these processes easier:

**Identity Management Dashboard**

- The Identity Management Dashboard is an interface for users to create their blockchain identity, and attach or revoke data connected to it.
- From the dashboard, a user can create an ERC725 identity, and attach a name, bio, and/or avatar to it. They will also be able to link Facebook, Github, and other social accounts, and access more advanced attestations like verifying citizenship or KYC status.
- When creating an ERC725, we also create an [username].commonw.eth. This allows individuals to utilize an existing namespace, and create a human-readable way for protocols to interact with each ERC725 identity. Additionally, this allows users an easy way with which to be sent any tokens. We maintain a registry of these linked ERC725 identities.
- We imagine this will be useful for relayers nudging their users to populate their blockchain identities -- when logged into the Dharma relayer mentioned earlier, users without a blockchain identity can be prompted to create one using the Identity Management Dashboard.
- Additionally, the Dashboard shows the set of approved credential issuers, a searchable index of claims they have issued, and an index of users which have requested or received claims.

**Identity API**

- The Identity API is a free service, similar to Infura, for fetching a complete set of identity information about any Ethereum address. A developer can query it from the backend (or a user can query it from the browser) to retrieve any or all information from a range of identity services, including ERC725 self-sovereign identities, ERC780 identity registry data, and data on protocols like Bloom.
- We imagine this will be useful for services like Dharma relayers, where users interact with many other parties on the blockchain that are usually only identified by their address. A relayer can simply plug in a call to the Identity API, and immediately see human-readable names and social verifications next to each Ethereum address.

## 4. Applications for Common Identity

Once an Ethereum identity or claim has been linked to an address, protocols are able to use them. To allow for non-collateralized loans, debt underwriters and creditors need to be able to verify the identity of individual debtors. For transparent and compliant security token transfers, security tokens (and issuers) need to tie KYC/AML claims to an identity. Certain voting schemes need a stable set of voters to ensure sybil resistant results which can be provided by an identity solution. 

### 4.1. Lending or Insurance Protocols

Protocols such as these carry counter-party risk. As such, any information on the debtor or purchaser of an insurance policy is needed by underwriters and creditors to price risk. This is especially true when any debtor or purchaser does not provide any collateral. Many classes of financial products function in this manner. 

By plugging into our API, protocols can look at public identities for individuals. One such example is Dharma, a protocol for decentralized debt issuance. This example assumes familiarity with the current protocol. Now: 

1. Dharma relayers can now offer real-identity loans (as opposed to pseudonymous loans)
2. Relayers and creditors can click through to see a identity/reputation history (how many loans they’ve offered/repaid, whether they’ve connected a Facebook, Twitter, etc.), as well as specify the type section of loans that they want to give. 
3. Real-world public reputation will become a positive signal. Good Dharma loans will be requested by people with real reputation, whereas non-collateralized loans to arbitrary addresses will have much higher default rates.

### 4.2. Security Token Platforms

Security tokens tie off-chain cash flows to on-chain ownership certificates. These cash flows may be from an individual artwork, corporations, real estate and more. While the benefits of tokenizing an asset on the blockchain are numerous, a notable benefit is instant liquidity. However, each security token needs to comply with different requirements based on the purchaser's jurisdiction. Abacus, Securitize, Polymath, Harbor, and Otis act as security token issuers. As such these platforms can benefit from privately attested claims to comply with token transfer restrictions well as provide governance and voting rights to individuals on the blockchain.When security token governance is formalized on-chain, It means having a truly open API, as opposed to a closed gated API. Different individuals and different organizations (DAOs) may be able to participate through votes through a unified dashboard.

### 4.3. Work Tokens and Protocols

A large majority of protocols have mechanics that can be described as work protocols. That is, tokens that accrue value not to shareholders, but to those who actually participate in the running of the network. In work token systems such as Livepeer, Keep, and Tezos, a method for passive-holders to delegate their token to an individual exists. In this way, passive stakeholders are able put their stake towards use for another delegator. In exchange for a separate worker running hardware or other infrastructure. By plugging into an identity standard, we can provide rich data on workers and other protocol actors. This includes allowing:

- **Delegators choose between different workers.** While protocols may define some "in-protocol" reputation, data beyond historical slashing rate are often necessary. For example, one may ask if this address/identity has a history of using money for protocol improvements?
- **Verification of staking to the correct identity.** Right now, the standard campaign process for staking token with a worker can be a bit annoying. On one site, an individual may campaign for voters and link to a different address than what is stated, the result is funds that are sent to the wrong address. At the worst, a malicious worker may purposely slash it's own stake. Our API should verify that the address one is sending to is, for example, owned by the same person

### 4.4. Governance and Social Networks

Every protocol needs governance. Governance allows networks to make decisions and often involve user interactions. Interactions may include voting (and delegation of votes), staking (and delegation of stake), or airdropping tokens to new users. Having a queryable API makes all of these interactions more simple. Use cases are listed below.

- **Token distribution for new chains and TCRs.** When launching a new chain (perhaps with Substrate) or creating a TCR, the initial distribution of token is incredibly important determining how a network grow. A common assumption is the security model of these protocols is that at least 50% of tokenholders acts honestly. Distribution based on a set of claims/identity was recently utilized by the Handshake Protocol. To seed a new root DNS authority, they distributed tokens to open-source developers. However, this was done by a centralized authority. By querying the standard API above, a new team is able to airdrop token to the correct set of individuals without needing a central authority. For example, these projects can distribute token to only those who have attested to their Github identity using a decentralized claims Issuance TCR.
- **Running incentivized RFCs and straw polls.** To come to a decision for a new standard, we circulate RFCs to the community. Yet now, the community has the (happy) problem of having too much development activity. We have an overwhelming amount of proposals from which to make a decision. By utilizing a market-based mechanism for attention, a community may be able to circulate RFCs and come to consensus on a standard more quickly. By querying the API, an author of an RFC is able to post a bounty to someone or a set of individuals who needs to answer some question. These bounties can be addressed to one specific ERC725 identity. Alternatively they may choose to send a bounty to individuals that fulfill some claim requirement, such as the amount of token held that has been provided by an anonymous claims construction.
- **Secure voting systems.** A pre-requisite to building a system for liquid democracy or quadratic voting is an implementation of an identity and claims standard. We need a sybil-resistant identity scheme, beyond pseudo-anonymous addresses to facilitate quadratic voting. Additionally, to allow for well-informed decisions for staking on liquid democracies, we need to be able to capture information on individual voting history. By querying the API, an individual may see claims on how another individual has voted, allowing them to make an educated decision on with whom to stake their vote. For a quadratic voting scheme, a stable identity and claims scheme allows votes to be restricted to a set of verified citizens or claim holders.

## 5. Conclusion

Relying on pseudo-anonymous addresses does not address issues facing protocols today. For example, debt issuers need identity to provide non-collateralized loans and security tokens need to tie KYC/AML claims to remain compliant. By building on an open standard,  this paper has outlined a standard specification for claims, a specification for a community-governed issuer of ERC725 identities, a method for decentralized claims issuance, and a queryable API. All these can be used by protocols to tie identity claims to pseudo-anonymous address. 

## Appendix: ERC725 Interface

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

## References

- [https://github.com/OriginProtocol/identity-playground/blob/master/README.md](https://github.com/OriginProtocol/identity-playground/blob/master/README.md)
- [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md) (ERC72)
- [https://github.com/ethereum/EIPs/issues/735](https://github.com/ethereum/EIPs/issues/735) (ERC735)
- [https://github.com/hicommonwealth/identity-tcr](https://github.com/hicommonwealth/identity-tcr) (Decentralized Claims Issuer)
- [https://medium.com/set-protocol/announcing-defi-an-alliance-of-decentralized-finance-platforms-f9ac78c39fba](https://medium.com/set-protocol/announcing-defi-an-alliance-of-decentralized-finance-platforms-f9ac78c39fba) (DeFi)
- [https://thecontrol.co/understanding-decentralized-identity-433abb343279](https://thecontrol.co/understanding-decentralized-identity-433abb343279) (Why Decentralized Identity)
- ERC725 Registry???

