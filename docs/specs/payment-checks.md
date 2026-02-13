# Payment Checks Spec

Status: Draft  
Owner: James Odom  
Goal: Define the exact Payment Check behavior for the initial testnet beta.

## 1) User stories
- As a sender, I can mint a Payment Check to a recipient using a supported token and amount.
- As a recipient, I can redeem a Payment Check and receive the underlying value.
- As anyone, I can view a Check and its full history in the Explorer.

## 2) Required decisions (must lock before coding)
- Recipient model:
  - Option A: direct recipient address only
  - Option B: claim link (adds complexity)
- Expiration:
  - Included or deferred
  - If included, what happens at expiration
- Cancellation:
  - Included or deferred
  - If included, who can cancel and when

## 3) Contract surface (draft)
- mintPaymentCheck(...)
- redeemPaymentCheck(checkId)
- getCheck(checkId)
- status(checkId)

## 4) Events (draft)
- PaymentCheckMinted(checkId, sender, recipient, token, amount, metadata?)
- PaymentCheckRedeemed(checkId, redeemer, token, amount)
- PaymentCheckCancelled(checkId, canceller) (if used)
- PaymentCheckExpired(checkId) (if used)

## 5) Deterministic status mapping (draft)
- Created when minted
- Redeemed after redeem event
- Cancelled after cancel event
- Expired after expiry event or state condition (if used)

## 6) Edge cases to test
- Double redeem attempt
- Unauthorized redeem attempt
- Wrong chain
- Unsupported token
- Zero amount
- Expired behavior (if used)
- Cancel behavior (if used)
