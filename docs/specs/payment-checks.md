# Payment Checks Spec (v1 Locked)

Status: Locked v1  
Owner: James Odom  
Last updated: 2026-03-06  

Goal: Ship NFT-based Payment Checks for the initial testnet beta, with instant and post-dated claim.

## 1) Summary
A Payment Check is an NFT-based, collateralized payment instrument.

Current testnet implementation:
- Contract: `packages/contracts/src/PaymentChecks.sol`
- Collateral token: fixed in constructor (testnet uses MockUSD)
- Custody: ERC-6551 token-bound account (TBA) per checkId
- Serial: stored on-chain (bytes32) and unique per check

## 2) Scope (v1)
In scope:
- ERC721 NFT-based checks (bearer instrument)
- ERC20 collateral escrowed into the check’s TBA at mint
- Instant Claim and Post-Dated Claim using claimableAt
- Transferable checks (ERC721 transfers)
- Owner-only redeem (redeem caller must be the current NFT owner)
- Void (issuer cancellation) only before claimableAt for post-dated checks
- Serial uniqueness enforced on-chain

Out of scope (deferred):
- Expiration and auto-return logic
- Protocol fees on-chain (UI may display fee estimate; fee collection is a later brick)
- Partial redemption
- Native token collateral (ETH)
- Signature-based claim links
- Advanced metadata and rendering pipeline baked into the protocol

## 3) Definitions
- Check NFT: ERC721 token that represents the payment instrument
- checkId: uint256 tokenId of the ERC721 NFT
- Issuer: the account that mints the check and supplies collateral
- Holder: the current owner of the ERC721 NFT
- Collateral token: ERC20 configured in constructor
- Amount: ERC20 amount escrowed into the TBA
- claimableAt: unix timestamp (seconds). The check cannot be redeemed before this time
- Serial: bytes32 identity, unique, generated off-chain
- Title: bytes32
- Memo: string, max 160 bytes
- Status: NONE, ACTIVE, REDEEMED, VOID

## 4) State machine
NONE -> ACTIVE -> REDEEMED (terminal)  
NONE -> ACTIVE -> VOID (terminal)

Rules:
- ACTIVE: collateral is escrowed and the check can become redeemable at claimableAt
- VOID: collateral returned to issuer and check is permanently non-redeemable
- REDEEMED: collateral paid to holder and check is permanently non-redeemable
- NFT remains in existence in all states

## 5) Required decisions (locked)
Recipient model:
- NFT holder model (bearer instrument)
- Redeem authority is the current NFT owner

Time rules:
- claimableAt == 0 means instant and is normalized to now
- Post-dated checks require claimableAt >= now

Void:
- issuer-only
- only while now < claimableAt
- after VOID, redeem must be impossible

NFT:
- never burned

## 6) On-chain data model (v1)
Per checkId, protocol stores:
- issuer (address)
- amount (uint256)
- createdAt (uint64)
- claimableAt (uint64)
- serial (bytes32)
- title (bytes32)
- memo (string, <= 160 bytes)
- status (enum)

Custody:
- Collateral is held by the ERC-6551 account created for this checkId
- The account is deterministic via registry.account(...) and created at mint

## 7) Contract surface (v1)
mintPaymentCheck(initialHolder, amount, claimableAt, serial, title, memo) -> (checkId, account)
- Creates the TBA
- Transfers collateral from issuer to TBA
- Mints NFT to initialHolder
- Stores check data (ACTIVE)

redeemPaymentCheck(checkId)
- Requires: ACTIVE, now >= claimableAt, msg.sender == ownerOf(checkId)
- Transfers collateral from TBA to the current holder
- Marks REDEEMED

voidPaymentCheck(checkId)
- Requires: ACTIVE, msg.sender == issuer, now < claimableAt
- Transfers collateral from TBA back to issuer
- Marks VOID

View helpers:
- getPaymentCheck(checkId)
- tokenIdForSerial(serial)
- accountOf(checkId)
- nextCheckId()

## 8) Events (Explorer requirements)
Explorer should index lifecycle from:
- PaymentCheckMinted(checkId, serial, issuer, initialHolder, token, amount, claimableAt, account)
- PaymentCheckRedeemed(checkId, redeemer, token, amount, account)
- PaymentCheckVoided(checkId, issuer, token, amount, account)
- ERC721 Transfer events for ownership history

## 9) Edge cases to test (minimum)
Mint:
- zero holder reverts
- zero amount reverts
- claimableAt in the past reverts (unless claimableAt == 0 treated as now)
- serial required and unique
- memo > 160 bytes reverts

Redeem:
- redeem before claimableAt reverts
- double redeem reverts
- unauthorized redeem reverts
- redeem after void reverts

Void:
- void after claimableAt reverts
- unauthorized void reverts
- void after redeem reverts
