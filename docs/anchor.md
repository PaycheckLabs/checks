# Checks Anchor

Owner: James Odom  
Last updated: 2026-03-06  

Purpose: single source of truth for scope, decisions, architecture, milestones, and workflow.

## 1) Snapshot
- What Checks is: programmable NFT Checks on-chain
- Current stage: public testnet build
- Current focus: Payment Checks v1 end-to-end (contracts + explorer UI)
- North star: security first, deterministic state, clean expansion later

## 2) Scope
Must ship (testnet MVP):
- Payment Checks end-to-end: mint, transfer, redeem, void
- Serial identity: unique serial stored on-chain, serial route on explorer
- Explorer UI mint flow (connect, mint, preview, mint tx, redirect to serial page)
- Deterministic status and lifecycle visibility

Deferred:
- Vesting Checks
- Staking Checks
- Yield routing and DeFi adapters
- Marketplace features
- Multi-chain expansion

## 3) Locked decisions
- Canonical spec: `docs/specs/payment-checks.md`
- No expiration in v1
- claimableAt:
  - claimableAt == 0 means instant (normalized to now)
  - post-dated checks redeemable only after claimableAt
- Void:
  - issuer-only
  - only while now < claimableAt
  - after VOID, redeem must be impossible
- NFT is never burned
- Serial and QR strategy: `docs/specs/serial-and-qr.md` (testnet route uses `/testnet/<SERIAL>`)

## 4) Canonical references
- Whitepaper / handbook (GitBook): https://paycheck-labs.gitbook.io/checks-whitepaper
- Canonical minting example: Jake Pays Rent
- Ignore hidden or invalid Gnosis Safe minting page (deprecated)

## 5) Repos and domains
- Contracts + docs repo: https://github.com/PaycheckLabs/checks
- Explorer UI repo (current UI work): https://github.com/PaycheckLabs/checks-explorer
- Live Explorer domain: https://explorer.checks.xyz
- Testnet serial route: https://explorer.checks.xyz/testnet/<SERIAL>

## 6) Architecture map (high level)
Components:
- Contracts (this repo)
- Explorer UI (checks-explorer)
- Indexer + SDK (future packages)

Contracts (canonical):
- `packages/contracts/src/PaymentChecks.sol` (ERC-6551 custody)
- `packages/contracts/src/ChecksAccount.sol` (ERC-6551 account implementation)
- `packages/contracts/src/MockUSD.sol` (test collateral token)

Legacy / compatibility:
- `packages/contracts/src/PaymentChecksLegacy.sol` (escrow-in-contract)
- `packages/contracts/src/PaymentChecksPCHK.sol` (deprecated wrapper name)

## 7) Payment Check lifecycle (v1 testnet)
Status enum: NONE, ACTIVE, REDEEMED, VOID

State machine:
- NONE -> ACTIVE -> REDEEMED (terminal)
- NONE -> ACTIVE -> VOID (terminal)

Deterministic status rule:
- Explorer derives status from on-chain state and events only

Required events (Explorer requirements):
- PaymentCheckMinted(checkId, serial, issuer, initialHolder, token, amount, claimableAt, account)
- PaymentCheckRedeemed(checkId, redeemer, token, amount, account)
- PaymentCheckVoided(checkId, issuer, token, amount, account)
- ERC721 Transfer events for ownership history

## 8) Fees (current plan)
- UI displays platform fee estimate: 0.05% (5 bps), charged in the collateral token
- Testnet target: fee routed to Checks Dev Wallet
- Mainnet target: fee routed to Checks Treasury Wallet
- Note: on-chain fee collection is a planned next brick (not assumed complete until implemented and tested)

## 9) Engineering workflow
- Main is the only long-lived branch
- Use feature branches and squash merge into main
- Prefer small commits that keep CI green
- No secrets in repo
- Tests required for mint, redeem, void paths
- Edge-case token behavior must be covered (no-return, false-return, reentrancy)

## 10) Next bricks (ordered)
1) Contracts: implement on-chain fee transfer (0.05% in collateral token)
2) Explorer: render preview check image card in UI, no serial or QR pre-mint
3) Explorer: generate and render final minted image with serial + QR after mint
4) Explorer: serial page upgrades (copy buttons, richer lifecycle data)
5) Indexer: formalize event scanning and serial mapping persistence
