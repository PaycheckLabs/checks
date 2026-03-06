# Amoy Deployment — Payment Checks (PCHK) — Legacy Archive

Status: Deprecated deployments retained for historical reference.  
Network: Polygon Amoy  
Chain ID: 80002

Canonical deployment:
- `docs/deployments/amoy-payment-checks.md` (this is the only deployment the UI should use)

## Core infrastructure (ERC-6551)

ERC-6551 Registry (canonical):
0x000000006551c19487814612e58FE06813775758

---

## Legacy deployment #1 (early wrapper deployment)

Deployed contracts:
- ChecksAccount (ERC-6551 account implementation):
  0xdB461838ef569A25c5493A1A38930FB091ec0Cfa
- MockUSD (mUSD, 6 decimals faucet token):
  0xa01C7368672b61AdE32FAEf6aeD5aeC1845dedb5
- Payment Checks (PCHK) address (wrapper-era deployment):
  0x4dC6db5f06DAF4716b749EAb8d8efa27BcEE1218

Smoke check (mint + redeem):
- Issuer / Holder:
  0x3E8f069a088369B62CAB761633b80fBCB941a379
- checkId:
  1
- serial (bytes32):
  0x414d4f592d44454d4f2d30303031000000000000000000000000000000000000
  (ASCII: "AMOY-DEMO-0001")
- TBA account:
  0x68109AC37eb936B332Ac800E213F0f1bc703b670
- Amount:
  100000000 (100.000000 mUSD)

Transaction hashes:
- ChecksAccount deploy:
  0xc78ebb1a64e2e72fd4783359f101622eb09622682c9246806a99f9e318d97ff7
- MockUSD deploy:
  0x56705a0a6d44fcbe4fd7a9a57d530229b3e897464969bf202fc64399a698e5bb
- Payment Checks deploy:
  0xf4a988cc10b9899d322803924182f72227c75b4793c0f7ce0c248eda9edba0a4
- Mint:
  0x7ba178aa07ebf7bcced11a65486319de96281430ddabe6f2086632683dc1f278
- Redeem:
  0x5d1f0f7cd8617d3bad436168f4a1a46717a7d58d4e7b9e9337e83a8d2fee981b

Notes:
- Broadcast log:
  packages/contracts/broadcast/DeployAndSmokePCHK6551.s.sol/80002/run-latest.json

---

## Legacy deployment #2 (wrapper name visible: PaymentChecksPCHK) (do not use)

Status: Deprecated. This exists only because it was deployed before the canonical “PaymentChecks” deployment was confirmed. Do not point the UI to this.

Deployed contracts:
- ChecksAccount:
  0x4e31e55D4D5167AD3343C3CD961Dc5D98a2f54E3
- MockUSD (mUSD):
  0xC64F0889bfa3d1a4377b602c11458155A64C2423
- PaymentChecksPCHK (wrapper):
  0x499B545F3da289B2B1670814a5458e03DdB41b12

Smoke check:
- issuer/holder:
  0x3E8f069a088369B62CAB761633b80fBCB941a379
- checkId:
  1
- serial:
  AMOY-DEMO-0001
- TBA account:
  0x30F7CCa544a3107a186c77422433Cf7923b07511
- amount:
  100000000 (100.000000 mUSD)

Transaction hashes (from broadcast output; some labels may be swapped — addresses above are authoritative):
- ChecksAccount deploy:
  0xa1eeb5ba4128e8f687453f29f0551497f2bde03f56d400b0eee55261c1d2c8f1
- MockUSD deploy:
  0x508385fb68930cc70586689d3f4f96b96ba5fd83299484fc5c05747e4805d1e8
- Mint:
  0xb348714c1b945531e37a27800c0bff96e82db0daf0f9aae9d8416151b0d4401b
- Redeem:
  0x63e6e81d4e719cac186229aefcd5129798f536ed3c52d22f1c0c60db792d9f67
