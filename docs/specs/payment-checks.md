# Payment Checks Spec (v1 Locked)

Status: Locked v1  
Owner: James Odom  
Last updated: 2026-02-14  
Goal: Ship NFT-based Payment Checks for the initial testnet beta, with instant and post-dated claim.

## 1) Summary

A Payment Check is an NFT-based, collateralized payment instrument.

- The check is an ERC721 NFT (the check itself).
- The collateral is an ERC20 amount escrowed by the protocol contract.
- Whoever holds the NFT controls the check.
- The holder can redeem the check once it is claimable.
- The issuer can void a post-dated check only before it becomes claimable.
- The NFT is never burned. It remains as a permanent on-chain record.

## 2) Scope (v1)

In scope
- ERC721 NFT-based checks (bearer instrument).
- ERC20 collateral escrowed at mint.
- Instant Claim and Post-Dated Claim using claimableAt.
- Transferable checks (ERC721 transfers).
- Owner-only redeem (redeem caller must be the current NFT owner).
- Void (issuer cancellation) only before claimableAt for post-dated checks.
- Explorer indexing from events, including VOID and REDEEMED states.

Out of scope (deferred)
- Expiration Handling and Expiration (no expiresAt in v1).
- Automatic return at a date (chain cannot auto-execute).
- Fees.
- Native token collateral (ETH).
- Partial redemption.
- Claim links or signature-based claiming.
- Complex metadata stored on-chain (names, memo, theme, category stay off-chain).

## 3) Definitions

- Check NFT: ERC721 token that represents the payment instrument.
- checkId: uint256 tokenId of the ERC721 NFT.
- Issuer: the account that mints the check and supplies collateral.
- Holder: the current owner of the ERC721 NFT.
- Token: ERC20 contract address used as collateral.
- Amount: ERC20 amount escrowed.
- claimableAt: unix timestamp (seconds). The check cannot be redeemed before this time.
- Reference: bytes32 optional correlation id for off-chain systems.
- Status: NONE, ACTIVE, REDEEMED, VOID.

Important note
- The check UI can show names (for example "Payment to Robert"), but on-chain identity is the holder address.
- Checks can be written to your own address (issuer can mint to self).

## 4) State machine

NONE -> ACTIVE -> REDEEMED (terminal)
              -> VOID (terminal)

Rules
- ACTIVE means collateral is escrowed and the check can become redeemable at claimableAt.
- VOID means collateral was returned to issuer and the check is no longer redeemable.
- REDEEMED means collateral was paid to the holder and the check is no longer redeemable.
- The NFT remains in existence in all states.

## 5) Required decisions (locked)

Recipient model
- Locked: NFT holder model. The check is an ERC721 and can be transferred.
- Redeem authority is the current NFT owner (owner-only redeem).

Instant vs Post-Dated
- Locked: both supported via claimableAt.
- Instant Claim uses claimableAt = block.timestamp (or mint input claimableAt = 0 which the contract treats as now).
- Post-Dated uses claimableAt in the future.

Expiration
- Locked: not included in v1. No expiresAt. No auto return.

Void (cancellation)
- Locked: included in v1 for post-dated checks only.
- Issuer can void only while block.timestamp < claimableAt.
- Void returns collateral to issuer.
- NFT remains with current holder and becomes a permanent VOID record.

## 6) On-chain data model (v1)

Each check stores:
- issuer (address)
- token (address)
- amount (uint256)
- createdAt (uint64)
- claimableAt (uint64)
- reference (bytes32)
- status (enum)

The current holder is tracked by ERC721 ownership, not stored in the check struct.

## 7) Contract surface (v1)

### mintPaymentCheck(initialHolder, token, amount, claimableAt, reference) -> checkId

Requirements
- initialHolder != address(0)
- token != address(0)
- amount > 0
- issuer has approved the contract to transfer amount of token
- If claimableAt == 0, contract sets claimableAt to block.timestamp
- Otherwise claimableAt must be >= block.timestamp

Effects
- Transfer amount of token from issuer to escrow (the contract)
- Mint ERC721 check NFT to initialHolder
- Persist check data with status ACTIVE
- Emit PaymentCheckMinted

### redeemPaymentCheck(checkId)

Requirements
- check exists
- status is ACTIVE
- block.timestamp >= claimableAt
- msg.sender == ownerOf(checkId) (owner-only redeem)

Effects
- Mark status REDEEMED
- Transfer escrowed token amount to the holder (owner)
- Emit PaymentCheckRedeemed

### voidPaymentCheck(checkId)

Requirements
- check exists
- status is ACTIVE
- msg.sender == issuer
- block.timestamp < claimableAt (void only before due date)

Effects
- Mark status VOID
- Transfer escrowed token amount back to issuer
- Emit PaymentCheckVoided
- NFT remains and is not burned

### View functions

- getPaymentCheck(checkId) returns the stored check struct
- getPaymentCheckStatus(checkId) returns status
- nextCheckId() returns the next id to be minted

## 8) Events (v1)

- PaymentCheckMinted(checkId, issuer, initialHolder, token, amount, claimableAt, reference)
- PaymentCheckRedeemed(checkId, redeemer, token, amount)
- PaymentCheckVoided(checkId, issuer, token, amount)

Transfer history is available from standard ERC721 Transfer events.

## 9) Deterministic status mapping for the indexer

From events only:
- If PaymentCheckVoided exists, status is VOID
- Else if PaymentCheckRedeemed exists, status is REDEEMED
- Else if PaymentCheckMinted exists, status is ACTIVE
- Else status is NONE

Remaining collateral
- ACTIVE: remainingCollateral = amount
- VOID or REDEEMED: remainingCollateral = 0

## 10) Edge cases to test (minimum)

Mint
- zero holder reverts
- zero token reverts
- zero amount reverts
- claimableAt in the past reverts (unless claimableAt == 0 which is treated as now)
- ERC20 transferFrom fails reverts

Redeem
- redeem before claimableAt reverts
- double redeem reverts
- unauthorized redeem reverts
- redeem after void reverts
- redeem nonexistent check reverts

Void
- void instant claim check reverts (claimableAt == now, so block.timestamp < claimableAt fails)
- void after claimableAt reverts
- unauthorized void reverts
- void after redeem reverts
- double void reverts
- void nonexistent check reverts

Transfers
- check NFT can be transferred at any time (standard ERC721 rules)
- redeem always pays the current holder
