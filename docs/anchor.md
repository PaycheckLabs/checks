# Checks Anchor
Owner: James Odom
Last updated: 2026-02-19
Purpose: Single source of truth for scope, decisions, architecture, milestones, and workflow.

## 1) Snapshot
- What Checks is: Programmable NFT Checks on-chain
- Current stage: Initial testnet beta build
- Current focus: Payment Checks v1 first
- North star: Security first, deterministic status, clean expansion later

## 2) Scope
### Initial testnet scope (must ship)
- Payment Checks end to end (mint, transfer, redeem, void, status, history)
- Explorer baseline (deterministic status, search, detail view)
- Minimal config for supported tokens and the testnet network
- Security baseline (tests, focused review on critical paths)

### Deferred (later stages)
- Vesting Checks
- Staking Checks
- Yield routing and advanced DeFi adapters
- Marketplace features
- Multi-chain expansion beyond the initial target chain(s)

## 3) Locked decisions
- PaymentChecks v1 spec is locked in: docs/specs/payment-checks-v1.md
- No expiration in v1.
- claimableAt:
  - claimableAt == 0 means instant and normalized to createdAt
  - post-dated checks are claimable only after claimableAt
- Void:
  - issuer-only
  - only while now < claimableAt
  - after VOID, redeem must be impossible
- NFT is never burned.

## 4) Canonical references
- Whitepaper / handbook (GitBook): https://paycheck-labs.gitbook.io/checks-whitepaper
- Canonical minting example: Jake Pays Rent
- Deprecated: hidden or invalid Gnosis Safe minting page should be ignored

## 5) Architecture map (high level)
- Components (planned):
  - Contracts
  - Explorer indexer logic
  - SDK (shared client functions and types)
  - Web app (later)
- Repo layout (planned):
  - packages/contracts
  - packages/indexer
  - packages/sdk
  - apps/web
  - docs/*

## 6) Payment Check lifecycle (v1 testnet)
- Status enum: NONE, ACTIVE, REDEEMED, VOID
- State machine:
  - NONE -> ACTIVE -> REDEEMED (terminal)
  - NONE -> ACTIVE -> VOID (terminal)
- Deterministic status rule:
  - Explorer derives status from on-chain state plus events, no guessing

Required events (Explorer requirements)
- PaymentCheckMinted(checkId, issuer, initialHolder, token, amount, claimableAt, referenceId)
- PaymentCheckRedeemed(checkId, redeemer, token, amount)
- PaymentCheckVoided(checkId, issuer, token, amount)
- ERC721 Transfer events for ownership history

## 7) Security rules
- No secrets in repo
- No mainnet value flow without audit + readiness checklist
- Tests required for mint, redeem, and void paths
- Minimal privilege and safe approvals
- Edge-case token behavior must be tested (no-return, false-return, reentrancy)

## 8) Milestones
- M0: Repo stabilized, CI green, first successful on-chain Amoy smoke run
- M1: Repeatable smoke coverage (transfer + void + post-dated claim) and stronger test suite
- M2: Explorer baseline (event index, deterministic status, check detail by id)
- M3: Basic web flow (connect wallet, mint, view, redeem)
- M4: Testnet beta release (deployed, verified, smoke-tested, monitored)

## 9) Backlog (next 10)
1. Expand DeployAndSmoke to cover transfer, void, and post-dated scenarios
2. Add Foundry tests mirroring real user flows and edge cases
3. Decide CI trigger policy (PR-only vs also push to main)
4. Add contract verification steps for Amoy
5. Create a deployments record for Explorer (amoy.json)
6. Define Explorer status reconstruction rules and data model
7. Implement minimal event scanner (block range, filters, pagination)
8. Build check detail view logic (by checkId)
9. Implement search primitives (by issuer, holder, token, status)
10. Do a focused review of escrow, approvals, and reentrancy assumptions

## 10) Open questions
- Supported token list for initial beta:
- Explorer indexing approach: lightweight scan vs The Graph
- Upgradeability approach for testnet:
- Expiration design for v2 (if needed) and settlement policy:
