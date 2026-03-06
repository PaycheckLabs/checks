# Serial and QR Strategy (Explorer and NFT Media)

Status: Draft (v1)  
Scope: Explorer and NFT check media.

## 1) Goals
- Human-readable serial printed on the NFT check image
- QR code that links to the canonical Explorer page for the serial
- Large serial space to avoid collisions at scale
- Avoid ambiguous characters (I vs 1, O vs 0)
- Keep v1 protocol simple and deterministic

## 2) Serial format
Display format:
LLL-NNNNLL-LLNN

Where:
- L = uppercase letter
- N = digit
- Hyphens are separators for readability

Example:
ABX-5249QY-MB63

Notes:
- Serials are always generated in uppercase
- No leading # is used

## 3) Allowed character set (ambiguity-free)
Letters (24):
A B C D E F G H J K L M N P Q R S T U V W X Y Z  
Excludes I and O

Digits (8):
2 3 4 5 6 7 8 9  
Excludes 0 and 1

Total combinations:
24^7 * 8^6 = 1,202,315,964,973,056

## 4) Generation and uniqueness
- Serials are generated off-chain using a cryptographically secure RNG
- Uniqueness is enforced on-chain in v1 by the PaymentChecks contract mapping serial -> tokenId
- Explorer treats serial as the primary human identity for a check

## 5) On-chain linkage (current build)
Current build stores:
- serial as bytes32 on-chain (unique)
- tokenIdForSerial(serial) exists to resolve serial -> checkId
- Explorer can fetch the check by checkId and show lifecycle + image

## 6) URL and QR strategy
Testnet serial landing route:
https://explorer.checks.xyz/testnet/<SERIAL>

Example:
https://explorer.checks.xyz/testnet/ABX-5249QY-MB63

Mainnet (later):
https://explorer.checks.xyz/<SERIAL>

QR rules:
- QR is generated after mint, when the serial exists and is confirmed on-chain
- QR payload should always be the canonical serial landing route, not a search page
- Serial lookup is case-insensitive for input, but canonical display is uppercase

## 7) Reserved routes and filters
Reserved site routes must never be treated as a serial.
Examples:
api, docs, about, admin, app, static, assets, favicon.ico, robots.txt, sitemap.xml, serial

Profanity filtering:
- Normalize by uppercasing and removing hyphens before checking
- Maintain the blocked list off-chain so it can evolve without protocol changes

## 8) Explorer requirements
Explorer must support:
- Serial landing page that maps serial to the underlying asset
- Resolve serial -> tokenId
- Display status and lifecycle: minted, redeemed, voided, transfers
- Show chain, contract, tokenId clearly
- Display the finalized check image after mint with serial + QR printed

## 9) Non-goals
- No expiration work in v1
- No requirement to derive serial from tokenId
