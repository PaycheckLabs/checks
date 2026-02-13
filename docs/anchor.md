# Checks Anchor

Owner: James Odom  
Last updated: 2026-02-12  
Purpose: Single source of truth for scope, decisions, architecture, milestones, and workflow.

## 1) Snapshot
- What Checks is: Programmable NFT Checks on-chain
- Current stage: Initial testnet beta
- Current focus: Payment Checks first
- North star: Security first, deterministic status, clean expansion later

## 2) Scope
### Initial testnet scope (must ship)
- Payment Checks end to end (mint, redeem, status, history)
- Explorer baseline (deterministic status, search, detail view)
- Minimal config for supported tokens and testnet network
- Security baseline (tests, static analysis, focused review on critical paths)

### Deferred (later stages)
- Vesting Checks
- Staking Checks
- Yield routing and advanced DeFi adapters
- Marketplace features
- Multi-chain expansion beyond the initial target chain(s)

## 3) Locked decisions
See docs/decisions for the canonical decision records.

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

## 6) Payment Check lifecycle (initial testnet)
- States (draft until we lock spec):
  - Created
  - Claimable (optional if separate from Created)
  - Redeemed
  - Cancelled (optional)
  - Expired (optional)
- Required events (draft until we lock spec):
  - PaymentCheckMinted
  - PaymentCheckRedeemed
  - PaymentCheckCancelled (if used)
  - PaymentCheckExpired (if used)
- Deterministic status rule:
  - Explorer derives status from contract state and events, no guessing

## 7) Security rules
- No secrets in repo
- No mainnet value flow without audit + mainnet readiness checklist
- Tests required for mint and redeem paths
- Minimal privilege and safe approvals

## 8) Milestones
- M0 Foundation: repo structure, docs, tooling choice, CI baseline
- M1 Payment Checks contracts: mint + redeem + event spec
- M2 Explorer baseline: deterministic status, search, detail page logic
- M3 App flow: wallet connect, mint UI, redeem UI (later)
- M4 Testnet beta live: deployed, verified, smoke-tested, monitored

## 9) Backlog (next 10)
1. Lock Payment Check spec: recipient model, expiration, cancellation, required events
2. Choose contracts toolchain and initialize packages/contracts
3. Implement mint and redeem with unit tests
4. Define deterministic status mapping for Explorer
5. Choose indexing approach for testnet (lightweight scan vs The Graph)
6. Implement explorer data model + status reconstruction
7. Implement search + check detail endpoints or modules
8. Add deploy scripts + verification steps for testnet
9. Add CI checks (tests, formatting)
10. Run a focused review on mint and redeem security edge cases

## 10) Open questions
- Target testnet network:
- Supported token list for initial beta:
- Recipient model: direct address only vs claim link:
- Expiration and cancellation rules:
- Indexing approach: The Graph vs lightweight event scan:
- Upgradeability approach for testnet:
