# ERC-6551 Foundation (Polygon Amoy)

Chain: Polygon Amoy  
Chain ID: 80002  
RPC: https://rpc-amoy.polygon.technology/

## Canonical addresses (Tokenbound v0.3.1)

Registry (ERC-6551):
0x000000006551c19487814612e58FE06813775758

Tokenbound Account Proxy:
0x55266d75D1a14E4572138116aF39863Ed6596E7F

Tokenbound Account Implementation:
0x41C8f39463A868d3A88af00cd0fe7102F30E44eC

## Verification (PowerShell)

```powershell
$RPC="https://rpc-amoy.polygon.technology/"

cast chain-id --rpc-url $RPC

cast code 0x000000006551c19487814612e58FE06813775758 --rpc-url $RPC
cast code 0x55266d75D1a14E4572138116aF39863Ed6596E7F --rpc-url $RPC
cast code 0x41C8f39463A868d3A88af00cd0fe7102F30E44eC --rpc-url $RPC
