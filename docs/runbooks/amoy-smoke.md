# Amoy Smoke Run (PaymentChecks v1)

## Purpose
Run a repeatable on-chain smoke for:
- mint + redeem
- transfer-before-redeem (requires second key for full coverage)
- post-dated redeem revert checks
- issuer void flow and redeem-after-void revert check

## Prereqs
- Foundry installed (forge available)
- Polygon Amoy RPC URL
- One funded Amoy account (issuer)
- Second funded Amoy account recommended (holder)

## PowerShell
```powershell
cd C:\Users\James\checks\packages\contracts

$env:AMOY_RPC_URL = "https://rpc-amoy.polygon.technology"
$env:PRIVATE_KEY = "0xISSUER_PRIVATE_KEY"
$env:SECOND_PRIVATE_KEY = "0xHOLDER_PRIVATE_KEY"  # optional but recommended

forge script script/DeployAndSmoke.s.sol:DeployAndSmoke --rpc-url $env:AMOY_RPC_URL --broadcast -vvv
