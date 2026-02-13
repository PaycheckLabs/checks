# 0001 Payment Checks first

Date: 2026-02-12

## Decision
Initial testnet beta ships Payment Checks first. Vesting Checks and Staking Checks are deferred.

## Reason
Reduce scope risk and ship a stable testnet faster while preserving security.

## Implications
- Contracts, explorer, and SDK are designed around Payment Checks lifecycle first.
- Vesting and staking are implemented later as separate modules without blocking testnet.
