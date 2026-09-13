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

## Explicit task lifecycle

The v0.3.26 stack provides opt-in per-task model/effort, one owned worktree,
canonical contexts, bounded resume, executed verification, critic/repair and
configured publication/deployment readback. See `abc-onboarding.md`. The source
starter carries no execution_defaults; example contracts are inputs to customize,
not authorization. Source maintenance profiles, decisions and history describe this
template and are removed from the inherited `.go` when `spike` customizes a copy.
