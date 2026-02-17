# checks

Checks Protocol and Explorer — programmable NFT Checks on-chain.

Initial testnet focus: **Payment Checks** (mint, transfer, redeem, void).

---

## What this repo is

This repository is a monorepo for the Checks ecosystem:

- **Protocol (smart contracts)**: the on-chain core for NFT Checks
- **Explorer / apps (future)**: UI surfaces for creating and managing Checks
- **SDK (future)**: developer tooling to integrate Checks into other products

Today, the priority is locking in the **Payment Checks MVP** on testnet with clean, reliable tests and a stable CI pipeline.

---

## Payment Checks MVP (current scope)

A Payment Check is an ERC-721 NFT that represents a claim on deposited ERC-20 funds.

High-level behavior:

- **Mint**: issuer deposits ERC-20 into the contract and mints a Check NFT to a holder
- **Transfer**: the NFT can be transferred like any ERC-721
- **Redeem**: the current NFT holder redeems the Check to receive the ERC-20 funds
- **Void**: issuer can void under defined rules (for example: before `claimableAt`)
- **Post-dated checks**: optional `claimableAt` timestamp that gates redemption

This repo’s tests aim to codify these rules precisely so the protocol stays predictable and safe.

---

## Repository layout (high level)

- `.github/workflows/`
  - CI workflows (includes a contracts-only workflow for Foundry)
- `packages/contracts/`
  - Foundry project and Solidity contracts/tests
- `apps/`
  - Future UI apps (Explorer, minting interfaces, etc.)
- `sdk/`
  - Future developer SDK

---

## Contracts (Foundry)

Contracts live under `packages/contracts`.

Typical local workflow (from repo root):

```bash
cd packages/contracts
forge --version
forge build
forge test -vvv
