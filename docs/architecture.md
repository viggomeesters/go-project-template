# Template Architecture

This template intentionally contains very little application code. The product is the `.go/` contract itself.

## Files

- `.go/project.json`: project identity and verification defaults.
- `.go/architecture-principles.json`: durable constraints.
- `.go/vision.json`: north star and non-goals.
- `.go/hierarchy.json`: epic-lite work packages and features.
- `.go/tasks/open/*.json`: claimable work.
- `.go/evidence/*.jsonl`: append-only evidence stream.

## Boundary

This template is not a central workflow database. Each real project owns a copied/adapted `.go/` folder.
