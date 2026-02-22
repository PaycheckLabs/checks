# Checks Anchor

Owner: James Odom  
Last updated: 2026-02-22  
Purpose: Single source of truth for scope, decisions, architecture, milestones, and workflow.

## 1) Snapshot
- What Checks is: Programmable NFT Checks on-chain
- Current stage: Testnet beta build
- Current focus: Payment Checks v1 first
- North star: Security first, deterministic status, clean expansion later
- Current milestone focus: M1, repeatable smoke coverage and identity layer groundwork

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
- PaymentChecks v1 spec is locked in: `docs/specs/payment-checks-v1.md`
- No expiration in v1
- claimableAt:
  - claimableAt == 0 means instant and normalized to createdAt
  - post-dated checks are claimable only after claimableAt
- Void:
  - issuer-only
  - only while now < claimableAt
  - after VOID, redeem must be impossible
- NFT is never burned
- Serial identity:
  - serial is not the tokenId
  - serial is uppercase and globally unique
  - testnet QR payload uses `https://explorer.checks.xyz/testnet/<serial>`
  - later plan: redirect `/testnet/<serial>` to `/<serial>` when mainnet Explorer is ready

## 4) Canonical references
- Whitepaper / handbook (GitBook): https://paycheck-labs.gitbook.io/checks-whitepaper
- Canonical minting example: Jake Pays Rent
- Deprecated: hidden or invalid Gnosis Safe minting page should be ignored

## 5) Architecture map (high level)
### Components (planned)
- Contracts
- Explorer indexer logic
- SDK (shared client functions and types)
- Web app (later)

### Repo layout (planned)
- packages/contracts
- packages/indexer
- packages/sdk
- apps/web
- docs/*

### Current repos and services
- Contracts and docs repo:
  - https://github.com/PaycheckLabs/checks
- Explorer repo (initial setup deployed):
  - https://github.com/PaycheckLabs/checks-explorer
  - Live domain: https://explorer.checks.xyz
  - Testnet serial route: https://explorer.checks.xyz/testnet/<serial>

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

## 8) Engineering workflow
- Main is the only long-lived branch
- Use feature branches and squash merge into main
- Prefer GitHub UI for edits and PR flow
- Use PowerShell only when critical (deploy scripts, local validation)
- No em dashes in team or community text

## 9) Current state highlights
### Contracts
- Spec lock: `docs/specs/payment-checks-v1.md`
- Core contracts:
  - `packages/contracts/src/PaymentChecks.sol`
  - `packages/contracts/src/IPaymentChecks.sol`

### Testing
- Foundry tests include additional and edge coverage:
  - `packages/contracts/test/PaymentChecks.additional.t.sol`
  - `packages/contracts/test/helpers/EdgeCaseERC20s.sol`

### Scripts and CI
- Deploy scripts:
  - `packages/contracts/script/DeployPaymentChecks.s.sol`
  - `packages/contracts/script/DeployAndSmoke.s.sol`
- CI workflow stable:
  - `.github/workflows/contracts.yml` installs forge-std before forge build and test
- Local tooling note:
  - `packages/contracts/foundry.lock` is ignored and should not be committed

### Explorer
- Explorer initial setup complete and deployed:
  - https://explorer.checks.xyz
- Current functionality:
  - `/testnet/<serial>` renders a lightweight check details page
  - Displays serial, chainId, contract, tokenId, and Polygonscan links
- Next Explorer upgrades:
  - Render NFT check image card on the serial page
  - Generate QR that links back to the serial page
  - Add metadata endpoints for wallet rendering later

## 10) Proofs and runbooks
### Proofs
- Amoy serial smoke proof document:
  - `docs/proofs/amoy/2026-02-20-deploy-and-smoke-serials.md`

### Runbooks
- Amoy smoke runbook:
  - `docs/runbooks/amoy-smoke.md`

### Local smoke run (PowerShell)
From `C:\Users\James\checks\packages\contracts`:
- Set:
  - AMOY_RPC_URL
  - PRIVATE_KEY
  - SECOND_PRIVATE_KEY
- Run:
  - `forge script script/DeployAndSmoke.s.sol:DeployAndSmoke --rpc-url $env:AMOY_RPC_URL --broadcast -vvv`
- Output artifacts:
  - `packages/contracts/broadcast/DeployAndSmoke.s.sol/80002/run-latest.json`
  - `packages/contracts/cache/DeployAndSmoke.s.sol/80002/run-latest.json`

## 11) Milestones
- M0: Repo stabilized, CI green, first successful on-chain Amoy smoke run
- M1: Repeatable Amoy smoke coverage (transfer + void + post-dated validation) and identity layer groundwork (serial system, testnet serial routing)
- M2: Explorer baseline (event index, deterministic status, check detail by id) and start moving from static mapping to a persistent mapping layer
- M3: Basic web flow (connect wallet, mint, view, redeem)
- M4: Testnet beta release (deployed, verified, smoke-tested, monitored)

## 12) Backlog (next 10)
1. Explorer: add image rendering endpoint and show check card on `/testnet/<serial>`
2. Explorer: generate QR that links to the serial page
3. Explorer: add metadata endpoint for wallet rendering (`/api/checks/metadata/<tokenId>`)
4. Contracts: update DeployAndSmoke to print testnet serial URLs (`/testnet/<serial>`) for Amoy runs
5. Contracts: keep expanding Foundry tests to mirror real user flows and edge cases
6. Docs: normalize markdown formatting in key docs that may be stored without proper newlines
7. Explorer: formalize serial mapping storage strategy (temporary JSON to indexer-backed mapping)
8. Explorer: define status reconstruction rules and data model for indexer
9. Explorer: implement minimal event scanner (block range, filters, pagination)
10. Security: focused review of escrow, approvals, and reentrancy assumptions

## 13) Open questions
- Supported token list for initial beta:
- Explorer indexing approach: lightweight scan vs The Graph
- Upgradeability approach for testnet:
- Expiration design for v2 (if needed) and settlement policy:
- Final canonical route policy for mainnet (redirect testnet route to canonical route when ready):
