# Contracts (Foundry)

This package contains the Checks Protocol smart contracts.

Current focus: Payment Checks v1 for testnet.

## What is a Payment Check (current build)
A Payment Check is:
- An ERC721 NFT (the check)
- Backed by ERC20 collateral held in an **ERC-6551 token-bound account (TBA)** created per checkId

Whoever holds the NFT controls the check:
- The current NFT owner can redeem once claimable
- The issuer can void only before the claimable time for post-dated checks
- The NFT is never burned and remains as a permanent record

## Canonical contracts
- `src/PaymentChecks.sol` (canonical, ERC-6551 custody)
- `src/ChecksAccount.sol` (ERC-6551 account implementation)
- `src/MockUSD.sol` (test collateral token for testnet)

Legacy (kept for history):
- `src/PaymentChecksLegacy.sol` (escrow held by the contract)
- `src/PaymentChecksPCHK.sol` (deprecated wrapper for back-compat name)

## Commands (optional local workflow)
From the repo root:
- Install dependencies:
  - `pnpm install`
- Build contracts:
  - `pnpm --filter @checks/contracts build`
- Run tests:
  - `pnpm --filter @checks/contracts test`

Foundry config is in `foundry.toml`. Solidity version is pinned there.

## Layout
- `src/` Contracts
- `src/vendor/openzeppelin/` Vendored OpenZeppelin subset (pinned in repo)
- `test/` Foundry tests
- `script/` Deploy and smoke scripts
