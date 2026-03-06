## Canonical deployment (preferred)

Payment Checks (PCHK) — contract: `PaymentChecks.sol`  
Status: ACTIVE (canonical)

ERC-6551 Registry (canonical):
0x000000006551c19487814612e58FE06813775758

PaymentChecks (PCHK):
0x9ED92dd2626E372DB3FD71Fe300f76d90aF2d589

ChecksAccount:
0x422DB2Ed65295b7F0e670AF29aD28fd3b2348c86

MockUSD (mUSD):
0x0D085A1EBb74f050cE3A8ed18E3f998F04A23268

Smoke check:
- checkId: 1
- serial: AMOY-DEMO-0001
- TBA account: 0x40F8562A219adDfd47973f13254a3E9e1258d7D7
- amount: 100000000 (100.000000 mUSD)
- issuer/holder: 0x3E8f069a088369B62CAB761633b80fBCB941a379

Transaction hashes:
- PaymentChecks deploy: 0x823c836cd641df617fb834cbefde3dd3b3f7eaed499ea3b23d509792922994b7
- Mint: 0xb9bcf30b7f3ed5c6e9c2069056e3155786d121cbfd08b26ad7963109c6298168
- Redeem: 0xa4884462537888fea3b204f9d7fe9f33c4ce47fd14b45347a441f69cec4f5624
- Approve: 0xc95894eb717aef640e23472f1ceb3ef8cfa6a0453eca0981c0b9a82435dd51ed
- Faucet: 0x03a169d6aec097cdf90299e75a158e0c321d62df46ee63a9c9f7b144287c83b4

Notes:
- This is the canonical deployment. UI should point to PaymentChecks above.
- ERC-721 name: Payment Checks (PCHK)
- ERC-721 symbol: PCHK
