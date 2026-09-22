# Bounded serial autonomy onboarding

This starter exposes the serial campaign behavior released in
`go-workflow-stack` v0.3.43. It does not enable an autonomous campaign by
default. A copied project must first choose its own goal, model profiles,
cumulative budget, release authority and deployment boundary. Unknown values
remain blockers.

Start with [guided project onboarding](abc-onboarding.md). That step selects the
project lifecycle, one task workspace policy, verification commands, version
source and release profile. It does not grant push or deployment authority and
does not create a campaign.

## Bind a campaign only after intake

Use `docs/examples/autonomy-campaign-answers.json` as a questionnaire, not as
an executable contract. Every `CHOOSE_*` value must be replaced from actual
user or repository authority. In particular:

- describe one observable goal and explicit non-goals;
- select only supported model/effort profiles;
- set one cumulative wall-clock, task and attempt budget for the whole run;
- name existing release profiles and independently authorize push;
- name deployment targets and authority, or select `none` with a truthful reason;
- retain all mandatory stop conditions.

Use `intake explore` to turn rough intent into ordinary `.go` tasks and preserve
every adopted outcome. Then materialize a versioned
`go-workflow.campaign-contract.v1` that binds the original intent hash, goal
outcomes, vision/principle hashes, accepted decisions, exact permitted tasks and
the collected authority. Validate it before execution:

```bash
./go validate . --campaign /path/to/campaign.json --json
./go auto . --campaign /path/to/campaign.json \
  --campaign-workspace-root /outside/repo/workspaces \
  --execute --agent <owner> --executor-agent <agent> \
  --max-commands <limit> --max-minutes <limit> --max-attempts <limit> \
  --ship-policy push --allow-push --json
```

The CLI flags are ceilings; they do not widen the contract. Omit
`--allow-push` or `--allow-deploy` unless the matching authority was explicitly
recorded. The controller remains serial and uses one owned worktree at a time.
It may continue across eligible tasks without another prompt, but it stops on
budget exhaustion, unresolved material choices, unsafe Git state, unknown
external effects or missing release/deployment proof.

Vision and architecture are relevance filters, not mandatory ceremony. A task
with no material architecture impact remains local. A material task must point
to an applicable accepted brief and exact accepted decision; the campaign
contract cannot invent that authority.

## What the starter proves

Run `make check-autonomy` (also included in `bash scripts/check.sh`). It clones
the committed starter, proves unanswered onboarding is read-only, applies
explicit lifecycle settings, and builds a bounded campaign from repo-local
state. A missing release-authority source is rejected before any worker starts.
With complete synthetic local authority, one controller completes two dependent
tasks, repairs a forced critic finding, publishes local Git tags `v1.2.0` and
`v1.3.0`, and finishes with an achieved outcome-bound goal audit.

The fixture uses deterministic native CLI doubles, disposable worktrees and a
local bare Git remote; it makes no model, hosted publication or deployment
calls. The stack's separate v0.3.43 proof records one real native-Codex synthetic
campaign with automatic interruption/resume. That measured run was 437.987
seconds with zero human interventions after launch. Neither proof establishes
eight-hour reliability, broad model quality, hosted effects or production
deployment safety.

Source maintenance records do not belong in a copied project's runnable queue.
This repository archives its completed maintenance intake under `.go/evidence/`;
a published clone contains only the reusable `task-schema-smoke` task. `adopt
--force` on a genuine new copy replaces the remaining source `.go` identity and
history with project-specific state.
