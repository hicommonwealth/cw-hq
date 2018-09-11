# Commonwealth Identity Whitepaper

## Abstract

## Privacy Tools

Privacy is at the core of our ultimate goals. There are a variety of privacy enhancing tools already available on Ethereum, and we plan to take advantage of that as well as lead the dialogue for new tools. Currently, there are precompiled contracts for cryptographic primitives based upon elliptic curves. There are also utilities such as `ecrecover` that allow recovery of the signer's public key. These basic primitives allow us to develop privacy enhancing technology using:

1. Zero-knowledge proofs
2. Commitment schemes
3. Blinding cryptography
4. Ring signatures

While some of these tools are more readily available than others, with regards to the costs of gas in a technology's respective computation, we define the systems that are paramount to Commonwealth's Identity standard.

## Privacy System #1 - Anonymous voting

Voting is a key piece in a governing system, allowing stakeholders to signal their preference over proposed alternatives. Anonymous voting allows individuals to do so privately. Similarly, these protocols are based at a high level on being able to prove membership in a set, one in which encompasses the claims made by such an identity (ownership of X coins or member of an arbitrary organization). Our approach to anonymous voting is twofold.

1. Zero-knowledge proof and cryptographic accumulator based voting protocols.
2. Ring signature based voting protocols.

**Zero-knowledge Scheme**

The former, zero-knowledge based, system has at its core a cryptographic accumulator such as a merkle tree. Users incrementally build the tree by submitting a provable claim about their identities. On the other hand, cryptographic accumulators can be built up front by trusted third parties endowing claims upon identities in the respective membership set. Examples are as follows:

1. ***Incremental construction:*** Alice wants to prove that she owns 50 LPT to participate in a Livepeer election, which endows token holders votes based upon an arbitrary vote pricing rule (1 coin, 1 vote). She deposits 50 LPT into a contract that enforces depositors to send exactly 50 LPT and also sends a hash of secret data as a function parameter. This hash is added as a leaf in the merkle tree. Alice then generates a clean address, potentially using a derived stealth address based upon a hierarchically deterministic wallet, and submits a vote using a zero-knowledge proof that she knows the pre-image of a hash that is also a leaf in the merkle tree, using a merkle proof. Alice has successfully voted without linking her vote to her depositing address.

  *Note: the security of this scheme, assuming the hash function is secure, is entirely dependent on how many individuals have also deposited into the contract. That is, the size of the anonymity set determines the link-ability of votes in the system.*

2. ***Upfront construction:*** A trusted third party like Github wants to allow users to vote on proposed future projects and since they have a database of active users can build a merkle tree of all valid users up to some time ***t***. Github can, similar in the example above, take a secret, hash it with the username of the valid user's account or other identifying information, and use this data as leaves in the merkle tree. Upon sharing the secret with respective users in the Github web application, user's can participate in the vote just as Alice did, by submitting zero-knowledge proofs of knowledge of the pre-image of a leaf node's hash and a merkle path asserting the existence of the data.

**Ring Signature Scheme**

The latter approach based upon ring signatures works with a different set of design constraints. Building a ring signature based mixing service requires setting a variety of parameters such as the size of the ring as well as the time necessary to close the initialization and voting process. As the size of the anonymity set determines some degree of the link-ability of votes in the system, the larger the better. However, the larger the anonymity set, the longer it takes to potentially finish the initialization step where users submit their public keys into the ring. These parameters require more thought and pose challenges to designing efficient schemes. Moreover, we now describe how a ring signature based scheme works in the same fashion as before with additional insight into extensions with ERC725 and ERC735 standards.

- ***Incremental construction:*** Alice wants to host a vote over a set of issues, potentially undefined up to this point, and wants to ensure that the vote is both anonymous and that only certain identities — those than can prove a specific claim — can vote. Thus she designs a ring that requires users to submit these proofs, in the form of a claim issued on an ERC735 compliant identity, in order to gain admission into the ring. Alice defines the constraints that allow eligible additions to the ring, potentially delaying the length of time required to fill up the specified ring size. Nonetheless, when valid identities based upon these standards fill up the ring in its entirety, identities need only submit proofs of membership and votes to engage in the anonymous voting protocol with a ring signature. Using linkable ring signatures, the contract can enforce the that no single identity votes twice or incentivize users to handle such work using incentives and fraud proofs.
- ***Upfront construction:*** Github wants to allow all its current users to vote on a new change in their product. They create a ring signature voting protocol contract and populate the ring with all the identities of their users, assuming all Github users have an associated ERC725/ERC735 compliant identity contract to stand in their place. Users simply follow the scheme defined above now that the accumulator has already been constructed and submit linkable ring signatures to cast votes.

## Privacy System #2 - Anonymous credential issuance

Integral to any of the voting implementations described above is the notion of having claims to prove membership of a set of identities, whether through merkle trees or ring signatures sets. While some claims are easier to describe than others, requiring no trusted third party such as token ownership, there are countless use cases for having a claims issuance service for trusted third parties. This system encompasses the crux of combining the centralized and decentralized world to build heavily useful technology. Better yet, a system that enables the anonymous issuance of credentials allows individuals to participate in claims-worthy protocols without disclosing the fundamental information that makes up such claims.

Credentials, at their core, are groups of claims. Credentials allow individuals to prove they have the necessary information and permission to access a protected resource or make certain claims about themselves or aspects of a system in general, usually without disclosing that information. Users of popular social media websites can now use OAuth to obtain a temporary credential that ensures such a user controls the password to an account, without using the password. Similarly, these schemes work by bootstrapping off mobile devices, which ensure that the user who set up such a service with the credential issuing entity (a trusted third party) has the information that grants access to the protected resource. Part of Commonwealth's Identity Protocol is building tools for allowing a rich, decentralized ecosystem of credential or claims issuing entities to grow.

In the proposed anonymous credential issuance service, a predominantly off-chain issuance application, users will use the Commonwealth Protocol to structure and design the claims they wish to receive from trusted third parties. These interactions will happen off-chain, but will be verifiable on-chain, allowing users and trusted third-parties the ability to add new credentials (groups of claims) to ERC735 compliant identities. Thus, new applications such as those described with Github will be possible. When trusted third parties have incentives to participate in the system, users will benefit from being able to add these claims to their blockchain based identities and further participate in the ecosystem's rich set of protocols for lending, voting, and more.

Within this system, there are paths for obtaining public and private credentials. Alice may want to prove publicly that she is at least 21 years or by using a credential issued by a trusted third party such as her local, state, or federal government.

## Privacy System #3 - Curation market for credential issuers and claims

Core to the privacy systems above is that of curating trusted third parties. While this system itself may not involved many privacy enhancing technologies past private voting, it should provide transparency to the evolution of verified credential issuers in the Commonwealth Protocol that are responsible for issuing privacy related claims on identities following ERC725 and ERC735 standards. There are two routes we plan to prioritize.

**Decentralized Autonomous Organization for TTP curation**

Commonwealth will be the initial stakeholder in the process for adding new, verified credential issuers using public and private voting schemes. As any DAO, this organization will allow stakeholders to propose and vote on potential additions and deletions of trusted third party credential issuers.

**Token Curated Registry for TTP curation**

In the same flavor of the DAO above, we instead structure the curation market as allowing any individual or organization the ability to propose new trusted third party credential issuers. This component can simultaneously be controlled by a DAO with a different flavor than above.

**Token Curated Registry for claims issuance**

Coming from the opposite direction, where users want to attest to claims, we can devise novel systems that utilize token curated registries for granted claims. That is, users who successfully pass the challenge process of a TCR can submit the inclusion in the TCR as a claim to other identity related products.

There is no way for a user to prove they have an external social media account unless the social media services issued a credential on their behalf. However, we can bootstrap the issuance of such a credential with a token curated registry (TCR) with the eventual Commonwealth Token. The process works by requiring identities to submit claims over external social media identities in the TCR. Upon inclusion in the TCR, the user is further required to send a hash of a secret to the respective contract that builds an incremental merkle tree for proving membership based upon the social media identity link (people who have Facebook accounts). Now, we have designed a decentralized, market derived claims issuer in the form of a token curated registry that permits successful listings to be included in a cryptographic accumulator. This accumulator serves as the backbone of some of the privacy systems defined above.

- Implementation:
  - Need to build smart contracts for the mixers
  - Need to build a dashboard + voting interface that shows who's in each accumulator, and results of each vote

## Technical Spec: Contract Interface

Found in the contracts folder within the github repo.

## Commonwealth Identity API

In order to get usage we propose several services built on top of Commonwealth identity:

- [commonwealth/api](http://commonwealth.id/api) API, similar to Infura, that provides information on an Ethereum address. (Dharma relayers, and other services, can use it to retrieve identity information stored on the blockchain)
  - Describe an API service that takes any Ethereum address and resolves it to a human-readable name, while allowing the application provider to additionally retrieve off-chain data from trusted custodians. ("You can make one API request to our servers and, if you have the right permissions, get everything on an ETH address...")
    - API will serve up Commonwealth identities, Bloom identities, and more
    - Describe how it can serve ERC725, Bloom, Blockstack, Civic and other identities
  - Describe how it works together with Metamask/other existing wallets
  - Describe how it can work cross-chain (this could be another section?)
- [commonwealth.id/](http://commonwealth.id/) (Management interface where you can see all your public keys, link social accounts, and request off-chain attestations from third parties including the Commonwealth Network/Web of Trust)
  - At [commonwealth.im](http://commonwealth.im/), create an account and sign a verification of that account
  - You can sign back into that account from Facebook, Twitter, Github, or Metamask. You can also attach an email and password
  - From our website, you can attach a bio to your identity, see all the services you’ve signed into, and revoke trusted-third-party data relay.

## Applications

1. Describe how a lending or insurance protocol might use Commonwealth Identities [public identities]
  - Dharma relayers can now offer real-name loans (as opposed to pseudonymous loans)
  - Relayers and creditors can click through to see a identity/reputation history (how many loans they’ve offered/repaid, whether they’ve connected a Facebook, Twitter, etc.), as well as specify the type section of loans that they want to give.
  - Real-world reputation will become a positive signal. Good Dharma loans will be requested by people with real reputation, whereas loans to arbitrary addresses will have much higher default rates.
  - A concern would be: local lenders could set up secure a legal contract, which they can send to collections and write to credit files, and then securitize on the blockchain. In the latter case, what's the role of/need for blockchain identity?
    - If it's being published to the blockchain but not in a publicly verifiable manner, then they're basically using Ethereum as a private blockchain.
    - If it's not being published to the blockchain in a publicly verifiable manner, that's fine — as long as the user can provably verify that they are the owner of a blockchain loan conducted on another system, parties on our system can simply spin up an attestor to pull in the data from their system. **There are natural aggregation effects to an identity platform on public blockchains.**
2. Describe how security token management might use Commonwealth identities [private identities, voting on the blockchain]
  - For Paradigm - accelerates their process
  - For Abacus, Securitize, Polymath, Harbor, Otis - many will end up using an external provider for corporate governance. As long as we show we can be trusted. We're not competitive with them, even if we start building our own issuing interfaces/marketplaces, as long as we partner with them and support them
  - Why put security token governance on the blockchain? It means having a truly open API, as opposed to a closed gated API
    - DAOs can vote on security token governance
3. Describe how work tokens and staking pools (e.g. Livepeer, Keep, Vest) can use Commonwealth Identity
  - Identify workers and stakers/capitalists
  - **Provide additional security for those staking their token, that they are sending it to the right identity**
    - Our API should verify that the address one is sending to is, for example, owned by the same person
4. Describe how a governance system might use Commonwealth Identities
  - For Polkadot - allows new chains to be spawned easily
  - For Repaird/Buy the Dip - allows a group to run the takeover
  - For Livepeer - staking DAOs (if they care)
    - Also, Gravatar reduces counterparty risk

## Conclusion

We have presented an identity service built upon the ERC725/ERC735 specifications, for accessing human-readable identities tied to blockchain addresses. In this paper, we have discussed details of its implementation, as well as specific applications towards financial services, gaming, and blockchain governance. Finally, we discuss how the protocol might be extended to support a rich ecosystem for identity and reputation.

## References

- [https://github.com/OriginProtocol/identity-playground/blob/master/README.md](https://github.com/OriginProtocol/identity-playground/blob/master/README.md)
- [https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-725.md)
- [https://github.com/ethereum/EIPs/issues/735](https://github.com/ethereum/EIPs/issues/735)

---

- @Raymond Z - describe UX of interacting with Miximus, since it requires interacting with many keys
- @Dillon Chen - flesh out applications, and more specific use cases

[Commonwealth/DeFi Credential Issuer](https://www.notion.so/9ab6066e33184574bc6d0f11d6522145)
