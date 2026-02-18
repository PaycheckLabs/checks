# Payment Checks v1 Spec Lock (Testnet)

Status: Locked for initial testnet launch  
Contract: `packages/contracts/src/PaymentChecks.sol`  
Interface: `packages/contracts/src/IPaymentChecks.sol`

## 1) Purpose

Payment Checks v1 are ERC721 NFTs backed 1:1 by escrowed ERC20 collateral held by the PaymentChecks contract. The NFT is transferable. The current NFT owner can redeem once the check is claimable.

v1 is intentionally minimal to support:
- A working testnet deployment
- A basic Explorer that can index checks and show state transitions
- Clear, testable rules for mint, transfer, redeem, void

## 2) v1 scope (what is included)

### Included behaviors
- Mint a Payment Check NFT with ERC20 collateral escrowed in the contract
- Transfer the NFT using standard ERC721 transfers
- Redeem by NFT owner after `claimableAt`
- Void by issuer only while post-dated and before `claimableAt`
- The NFT is never burned (even after redeem or void)

### Time rules
- `claimableAt == 0` means "instant" and is normalized to `createdAt`
- Post-dated checks have `claimableAt > createdAt`
- No expiration logic exists in v1

## 3) Non-goals for v1

These are explicitly out of scope for the initial testnet:
- Expiration of checks and automatic fund return
- Fees, royalties, or protocol takes
- Token bound accounts (TBA) custody
- Partial redeems
- Multiple tokens per check
- On-chain metadata beyond `tokenURI` base prefixing
- Permissioned minters or allowlists

## 4) Data model

Each check stores:
- `issuer` (address): the minter of the check
- `token` (address): ERC20 collateral token
- `amount` (uint256): collateral amount escrowed
- `createdAt` (uint64): timestamp at mint
- `claimableAt` (uint64): timestamp when redeem becomes allowed
- `referenceId` (bytes32): off-chain reference (optional, not enforced unique)
- `status` (enum): NONE, ACTIVE, REDEEMED, VOID

State machine:
- NONE -> ACTIVE -> REDEEMED (terminal)
- NONE -> ACTIVE -> VOID (terminal)

## 5) Authorization rules

- Mint: any caller can mint, caller becomes `issuer`
- Transfer: standard ERC721 transfer rules apply
- Redeem: only current NFT owner can redeem
- Void: only issuer can void, and only while the check is still post-dated

## 6) Function specs

### mintPaymentCheck(initialHolder, token, amount, claimableAt, referenceId)
Preconditions:
- initialHolder != address(0)
- token != address(0)
- amount > 0
- claimableAt normalized: if claimableAt == 0 then claimableAt = now
- claimableAt must not be in the past (claimableAt >= now)

Effects:
- Escrows `amount` of `token` from issuer into contract
- Mints ERC721 checkId to `initialHolder`
- Stores PaymentCheck record with status ACTIVE
- Emits PaymentCheckMinted

### redeemPaymentCheck(checkId)
Preconditions:
- check exists
- status == ACTIVE
- msg.sender is current NFT owner
- now >= claimableAt

Effects:
- status becomes REDEEMED
- Transfers escrowed ERC20 to current NFT owner
- Emits PaymentCheckRedeemed

### voidPaymentCheck(checkId)
Preconditions:
- check exists
- status == ACTIVE
- msg.sender is issuer
- now < claimableAt

Effects:
- status becomes VOID
- Transfers escrowed ERC20 back to issuer
- Emits PaymentCheckVoided
- NFT remains owned by current holder, but is permanently non-redeemable

## 7) Events (Explorer requirements)

Explorer can index check lifecycle from these events:
- PaymentCheckMinted(checkId, issuer, initialHolder, token, amount, claimableAt, referenceId)
- PaymentCheckRedeemed(checkId, redeemer, token, amount)
- PaymentCheckVoided(checkId, issuer, token, amount)
- ERC721 Transfer events for ownership history

## 8) Errors and failure conditions

Interface-defined errors:
- CheckNotFound
- CheckNotActive
- InvalidHolder
- InvalidToken
- InvalidAmount
- InvalidClaimableAt
- NotOwner
- NotIssuer
- NotClaimableYet
- TooLateToVoid

## 9) Security and token compatibility assumptions

- Any ERC20 can be used, but fee-on-transfer or rebasing tokens may not behave as expected for 1:1 escrow accounting.
- Reentrancy is guarded on mint, redeem, void.
- Collateral is escrowed in the PaymentChecks contract for v1.

## 10) Planned v2+ extensions (not implemented in v1)

- Expiration with a defined settlement policy (fund return rules)
- More advanced custody (TBA, Safe, escrow plugins)
- Fees and/or protocol configurable economics
- Metadata expansions, richer Explorer fields
