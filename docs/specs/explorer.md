# Explorer Spec (Initial Testnet)

Status: Draft  
Goal: Explorer must show deterministic status and history from contract state and events.

## Must have
- Search by Check ID
- Search by wallet address (sender and recipient)
- Check detail view
- Full activity history per check

## Data requirements
- Events must contain enough fields to reconstruct history without guessing.

## Indexing options (choose one for testnet)
- Lightweight event scan (fastest to start)
- The Graph subgraph (more scalable later)
- Custom indexer + DB (more control, more work)
