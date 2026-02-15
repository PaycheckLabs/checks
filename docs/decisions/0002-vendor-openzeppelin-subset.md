# 0002: Vendor OpenZeppelin subset in contracts package

Date: 2026-02-14
Status: Accepted

## Context
We are building the Payment Checks contracts in a monorepo where the primary workflow is editing files directly in the GitHub UI. Using Foundry external dependencies (forge install) would add friction and can drift over time if not pinned.

## Decision
Vendor a minimal subset of OpenZeppelin Contracts v5.0.2 into the repository under:
- packages/contracts/src/vendor/openzeppelin

We keep the original SPDX headers and do not modify the vendored files.

## Consequences
- Pros: deterministic builds, no external installs, easier GitHub UI workflow
- Cons: larger repo footprint, manual updates if we upgrade OpenZeppelin later

## Follow ups
If the team switches to local development, revisit this decision and consider replacing the vendored folder with a pinned Foundry dependency plus remappings.
