# Contracts (Foundry)

This package contains the Checks Protocol smart contracts.

Current focus: Payment Checks v1 for testnet.

## What is a Payment Check

A Payment Check is:
- An ERC721 NFT (the check)
- Backed by escrowed ERC20 collateral (held by the contract)

Whoever holds the NFT controls the check:
- The current NFT owner can redeem once claimable
- The issuer can void only before the claimable time for post-dated checks
- The NFT is never burned and remains as a permanent record

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
