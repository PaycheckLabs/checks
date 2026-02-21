# Serial Blacklist Rules

Status: Draft  
Scope: Off-chain serial generation and Explorer lookup only.

## 1) Purpose
Prevent serials that:
- conflict with reserved site routes
- contain profanity or harmful terms
- create impersonation or brand risk

## 2) Normalization for filtering
Before checking a serial against the blacklist:
- Uppercase the serial
- Remove hyphens

Example:
ABX-5249QY-MB63 -> ABX5249QYMB63

## 3) Reserved routes
The Explorer reserves certain routes that must never resolve as a serial.

Examples:
api
docs
doc
about
admin
app
static
assets
serial
favicon.ico
robots.txt
sitemap.xml

Rules:
- Explorer should check reserved routes before attempting serial lookup.
- Serial generation should avoid producing a serial that matches a reserved route or conflicts with future planned routes.

## 4) Profanity and harmful substring filtering
Maintain a blocked list off-chain. Do not hardcode this on-chain.

Rules:
- Reject a serial if the normalized serial contains a blocked term.
- Keep the blocked list private and updateable.

## 5) Optional readability rules
If needed later:
- Reject excessive repeats
- Reject patterns that are hard to read or easy to mis-copy
