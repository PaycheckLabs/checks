# checks

Checks Protocol and Explorer: programmable NFT Checks on-chain.

Initial testnet focus: **Payment Checks** (mint, transfer, redeem, void).

## What this repo is
This repository is a monorepo for the Checks ecosystem:
- **Protocol (smart contracts)**: the on-chain core for NFT Checks
- **Explorer / apps (future consolidation)**: UI surfaces for creating and managing Checks
- **SDK (future)**: developer tooling to integrate Checks into other products

Today, the priority is locking in the **Payment Checks MVP** on testnet with clean, reliable tests and a stable CI pipeline.

## Payment Checks MVP (current scope)
A Payment Check is an ERC-721 NFT that represents a claim on ERC-20 collateral.

Custody model (testnet / current build):
- Collateral is held in an **ERC-6551 token-bound account (TBA)** created per `checkId`
- The NFT holder controls redemption once the check becomes claimable
- The issuer can void only under defined rules (post-dated and before claimable time)

Behavior:
- **Mint**: issuer funds the check’s TBA and mints the NFT to the holder
- **Transfer**: the NFT can be transferred like any ERC-721
- **Redeem**: the current NFT holder redeems to receive the ERC-20 collateral
- **Void**: issuer can void only while post-dated and before `claimableAt`
- **Post-dated checks**: optional `claimableAt` timestamp that gates redemption

## Quick links
- Checks whitepaper (handbook): https://paycheck-labs.gitbook.io/checks-whitepaper
- Explorer UI repo (current UI work): https://github.com/PaycheckLabs/checks-explorer
- Live Explorer domain: https://explorer.checks.xyz

## Contracts (Foundry)
Contracts live under `packages/contracts`.

Typical local workflow (from repo root):
```bash
cd packages/contracts
forge --version
forge build
forge test -vvv
