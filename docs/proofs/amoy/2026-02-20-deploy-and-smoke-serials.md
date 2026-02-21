# Amoy Proof: DeployAndSmoke Serial Mint Coverage (2026-02-20)

Status: Complete  
Network: Polygon Amoy  
chainId: 80002

## Summary
This proof run confirms that PaymentChecks v1 can be deployed and exercised end to end on Amoy with serial-based identity output. The smoke run covers:
- Deploy PaymentChecks and MockERC20
- Mint and redeem an instant check (issuer)
- Mint, transfer, and redeem an instant check (holder)
- Mint a post-dated check, verify it is not claimable yet, transfer it, and void it (issuer)
- Serial URL format printed for each minted check

QR and Explorer identity target:
- Canonical serial landing route: https://explorer.checks.xyz/<SERIAL>
- Example: https://explorer.checks.xyz/SMJ-4656RY-MA73

Transactions saved by Foundry:
- Broadcast: C:/Users/James/checks/packages/contracts/broadcast/DeployAndSmoke.s.sol/80002/run-latest.json
- Sensitive: C:/Users/James/checks/packages/contracts/cache/DeployAndSmoke.s.sol/80002/run-latest.json

## Deployed Contracts
PaymentChecks (ERC-721):
- Address: 0x74A3Ee6061c6619c3Ee3B6BC21344Aae8C2B735B
- Deploy TX: 0xc8441a1488c0477fa471c4143d3250615576f418ef8388a2cacf9f8836e1bb06

MockERC20 (mUSD, ERC-20):
- Address: 0x317A8a8Ab1Be364fF6001e0442Ec88E295f04626
- Deploy TX: 0x683f8053c937bbcf7224ef161b12a3aca2b26661cdde04f9f7a237d54aa7a288

## Smoke Run Wallet Roles
Issuer:
- 0x3E8f069a088369B62CAB761633b80fBCB941a379

Holder:
- 0x0D5d6388e3E512a94a52284B36DB802De2226330

## Token Setup Transactions
MockERC20 mint (fund issuer):
- TX: 0xae73ccbfa667634eaec49352ed1f14ba31bf7d57bddb723fb8aa9d9c60db2a84

MockERC20 approve (allow PaymentChecks escrow transfers):
- TX: 0x1467994b0fe82231ad0cfdf5f1e86669aa2216f71bfb259ca8ebf746e3f44e4e

## Checks Minted and Lifecycle Coverage

### CheckId 1 (Instant, Redeem by issuer)
Serial:
- SMJ-4656RY-MA73

Serial URL:
- https://explorer.checks.xyz/SMJ-4656RY-MA73

Mint TX:
- 0x0bae32cb1c486c83ba808c1d6f470c2cb781b8055dc8daea3b5dce576e71218e

Redeem TX:
- 0x0f7ba6f167f0f3ef45b1f190a3a41ca4729b592ee2f57976eecb2b9878006317

Coverage:
- mintPaymentCheck
- redeemPaymentCheck (issuer as owner)

### CheckId 2 (Instant, Transfer then redeem by holder)
Serial:
- FWK-3526CD-ML25

Serial URL:
- https://explorer.checks.xyz/FWK-3526CD-ML25

Mint TX:
- 0xde3650c200919aff0a60c9a39fe1ef61b2e54d2ef84d473479599c62385c3fcc

Transfer TX:
- 0x39a617a527aa168ecf4f5dcfab01ff4ca823320c9e09b19afb1d2bd9ca058644

Redeem TX:
- 0x244c6552b65653e46ec8bdd645bf11c92575d5569584b434661127b14eaf9a4f

Coverage:
- mintPaymentCheck
- ERC-721 transferFrom (transfer-before-redeem)
- redeemPaymentCheck (holder as new owner)

### CheckId 3 (Post-dated, Not claimable yet, Transfer, Void)
Serial:
- PDB-7968ND-KR54

Serial URL:
- https://explorer.checks.xyz/PDB-7968ND-KR54

Mint TX:
- 0x397a8b9f5e3d48474b35b639d1b2b711b051eccaa84b176e632d83da5eb32699

Transfer TX:
- 0x89a47a38362938a007ffa0c9981df6001f2e82aa36e1e1a8e6ea6762bc5b5b0d

Void TX:
- 0x8e2480ac6372f55e2fb39152616bb9de1c7c3c0dfeb2828d88b6627055b29437

claimableAt (from script output):
- 1771656447

Coverage:
- mintPaymentCheck (post-dated)
- not claimable yet validation (pre-claimableAt)
- ERC-721 transferFrom (post-dated transfer)
- voidPaymentCheck (issuer void while post-dated)

## Notes
- This proof run confirms the serial landing URL format and that each mint prints a serial suitable for Explorer routing.
- Serial lookup in Explorer should be case-insensitive and normalize to uppercase.
- The PaymentChecks v1 protocol intentionally skips expiration.
