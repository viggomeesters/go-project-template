# Explicit A/B/C onboarding

The exact current stack version and immutable commit are generated in the
[README pairing block](../README.md); both project pin fields and that block are
checked by `make check`. This starter remains `project_mode: template` and has
no `execution_defaults`. `task-schema-smoke` is a reusable mechanical contract
check; it does not select a model or represent an app release.

A new project must choose its own values before product execution. The existing lifecycle/profile/task JSON files under `examples/abc/` are
schema-valid planning inputs. `onboarding-answers.example.json` is an intentionally
unresolved questionnaire: replace its choices before validation. `CHOOSE_*` and
`CUSTOMIZED_PROJECT_ID` are placeholders, not working defaults. An unknown model
or missing command/remote is supposed to block execution.

| Input to collect | Where it belongs |
| --- | --- |
| Observable app outcome and real checks | Task acceptance, `verification`, and pending R# coverage |
| Supported model ID and reasoning effort | `execution_defaults.model`, or a task execution-contract override |
| Optional separate critic model/effort | `critic_model`; existing run selections remain frozen |
| Existing base branch and workspace policy | `workspace.base_branch`, `task_worktree`, `repo_local_single_writer` |
| Actual text/JSON/TOML product version source and bump | Named release profile `publication.version` and `bump` |
| Permitted remote, branch and publisher | Named release profile; a GitHub profile also needs the user's exact owner/repository |
| Changelog and all touched product files | The task's `scope.modify`, including version/changelog paths |
| Phase inputs, outputs, proof, stops and handoff | A selected `phase_profile`, with project-specific scope/checks |
| Required deployment or explicit reason for none | Separate deployment profile; target and readback must be explicit |

Use `lifecycle-settings.example.json` as a starting point. Its Git-tag profile is
an example choice, not the user's destination. `github-profile.example.json` shows
the additional GitHub fields. Neither settings nor a model choice grant push or
deployment authority. A required deployment needs its own target, command adapters,
idempotency support, observation contract and explicit initial `--allow-deploy`.
Do not use the example `mode: none` for a product that requires a live deployment.

The controller supports static text, JSON and TOML version sources. For TOML,
choose a dotted key such as `project.version` or `tool.poetry.version`; for JSON,
provide its configured key. Dynamic versions and unsupported/ambiguous formatting
are rejected before release writes. Select an existing static `X.Y.Z` source or
explicitly create the project's chosen initial version first.

## Guided customization of a new copy

Use Python 3.11 or newer, Git and the project's selected agent runtime. For example,
`uv run --no-project --python 3.12 ./go ...` supplies a compatible Python. `PYTHON`
may name one Python executable; it is not a shell command string.

The user describes the project through **Go**. The agent gathers missing choices,
reuses choices already explicit in the conversation, and operates these internal
steps. Start with a read-only facts/questions preview:

```bash
./go onboarding plan . --json
./go onboarding plan . --answers /path/to/answers.json --json
```

The planner detects candidate version sources, current branch, remote names and
possible checks. Detection does not execute checks or select policy. Fill the
answer example with the real model/effort, checks, task, base branch, version,
bump, tag prefix, changelog and publisher. A GitHub publisher also needs an exact
`repository` (`owner/name`). For no deployment use `mode: none` with a reason;
otherwise provide the explicit supported deployment configuration. Optional
`critic_model` chooses a separate critic profile.

A `needs_configuration` result lists remaining questions. A `ready` result contains
reviewable `settings` and `execution_brief` objects. Save those objects as separate
JSON files outside the project while customizing. Readiness validates configuration;
it does not attest model availability, working credentials, executable checks or
permission to publish. Version and changelog paths are included in the generated
task scope, alongside the supplied product paths.

Only for a **new copy of this template**, after checking its identity and preserving
any wanted source information, apply the reviewed settings and brief:

```bash
./go adopt . --force --project-id my-project --name "My Project" \
  --lifecycle-settings /path/to/settings.json
./go recommendation create . --brief /path/to/brief.json \
  --authority execute --authority-source imperative
./go go . --write --json
```

`adopt --force` replaces inherited `.go`; never use this recipe on the maintained
template source or an existing app with workflow history. It removes inherited
source tasks, claims, dependency mappings and maintenance profiles. The last two
commands create the exact planned first task, initially open and unclaimed; they
do not execute it. Use execute authority only when the user actually authorized
execution. A planning-only request must remain planning-only.

Before execution, review the new project's vision/architecture and the concrete
task, run validation, and follow its Go preflight. Required real architecture
choices cannot be inherited from the starter. The controller then runs the task
with explicit workspace/run identity and authorized shipping policy. Settings and
intake authority alone do not grant remote-write or deployment rights.

`spike --lifecycle-settings` remains available for broader project scaffolding.
It creates preset task scopes: refine matching generated tasks before claim,
including real version/changelog paths and product checks. Do not create duplicate
work. The guided brief path above preserves the supplied first-task scope directly.
`task.example.json` and the lifecycle/profile examples remain available for later
tasks and explicit per-task model overrides.

For an existing project's legacy tasks, preview lifecycle adoption instead:

```bash
./go migrate . --lifecycle --config /path/to/settings.json --json
./go migrate . --lifecycle --config /path/to/settings.json --apply --json
```

Adoption requires quiescent state, preserves existing overrides/history and grants
no execution authority. Keep its journal for supported resume or rollback. A stack
pin update alone does not adopt model/release defaults. Exact-target stack upgrade
previews validate disposable copies of the durable contract with the target runtime
before an apply; they are trusted-code checks, not an OS sandbox.

Model availability and effort support are checked before native launch. The runtime
enforces requested arguments; effective provider identity remains unconfirmed unless
separately attested. No in-flight profile edit or mid-turn hot switch is supported.

## One task workspace and a complete release

The canonical controller owns `.go`, phase checkpoints, current raw evidence and
outcome updates. Native workers receive verified context snapshots and use the same
owned task worktree across build, critic and repair. Workers report R# evidence;
they do not need to write canonical state outside their sandbox. The critic is
read-only and judges the prepared candidate before publication. Release/deployment
receipts remain pending until the controller observes them, and missing proof
prevents `done`.

Start the controller in the **primary project checkout**. A linked runtime is
supported; an arbitrary linked project checkout is not a second controller. Read
from an owned task worktree as needed, but keep controller mutations in the primary
checkout. The initial managed execution binds owner, run, task, workspace path/branch and
existing base commit explicitly. Later continuation uses its stored resume command;
it does not silently choose another workspace or model. Preserve dirty/unmerged
work and surviving workers. Cleanup is a separate stage after integration and
required release proof; retrying cleanup must not republish. Worktrees organize Git
state and do not isolate credentials, dependencies, test environments or external
effects. Fresh workers are supported; persistent-session/subagent adapters remain
deferred in the released stack.

`GO_STACK` may select a clean ordinary checkout **or a valid linked worktree** at
the exact pinned annotated tag/commit. The launcher rejects mismatched/dirty explicit
runtimes without resetting them. It honors an explicit Python executable and never
uses the retired vault. Default bootstrap uses a ref-specific cache, preserving
sibling development checkouts. Production use must not enable `GO_STACK_ALLOW_DEV`.

## Source maintenance and evidence

The source template's `template-source-maintenance` profile is a read-only Git-tag
verifier, and `dependency_projects` identifies its stack source dependency. Neither
is selected by new-project defaults; customization removes both. Keep active and
pending template maintenance out of published starter queues. Completed task records,
raw checks and release readback are preserved as non-executable source history under
`.go/evidence/`. Retain local canonical records until dependent source tasks complete,
then archive the completed maintenance queue with its proof intact. The reusable
smoke stays open. Do not fabricate historical completion or rerun archived work.

Onboarding checks make no model calls. The actual Terra High/Astra Medium two-release
sample and its two preserved failures are in the stack's
[v0.3.26 evidence](https://github.com/viggomeesters/go-workflow-stack/blob/v0.3.26/.go/evidence/abc-10-live/manifest.json).
It used a disposable development candidate whose 53 runtime file hashes match
the historical v0.3.26 release. The campaign verifies those hashes from that
annotated tag, separately from testing the current pinned runtime. It proves those native local Git releases, not hosted deployment access or
general model quality. Template v0.3.16 added the complete fresh clone/linked-worktree campaign below.


## Reproduce the template campaign

Run `bash scripts/test-abc-template.sh` (or `make check-abc`) with Python 3.11+
and `uv` available. It selects the exact pinned stack, then creates disposable
ordinary project clones, linked project views/owned task worktrees, and ordinary
or linked runtime checkouts. The unregistered linked view is rejected as a second
controller before worker launch; execution uses the primary controller. Each project is customized through
the real launcher and intake; generated scope/checks are explicitly refined before
claim. No source maintenance queue or model default becomes project authority.

The first task uses Terra High for build/repair and Astra Medium for its read-only
critic; the second uses Astra Medium. A deterministic native CLI double supplies
the capability catalog and phase responses: **these checks make no model calls**.
The controller, context snapshots, validators, worktrees, versioning, local Git
remotes and release readback are real. Both projects deliver v1.2.0 then v1.3.0.

The campaign pauses after build, resumes the same run/workspace, rejects early
dependency execution, carries critic feedback into repair, and checks unmerged-index
preservation, serial tag ancestry and completion retry without repeated workers or
publication. It prints release and verification receipts. Separate released-stack
regressions exercise lost push/publish acknowledgements, unknown remotes, changed
model selection, unavailable critic capabilities, dirty cleanup and cleanup retry.
Migration regressions also apply, resume and roll back real contract journals while
preserving existing overrides and historical bytes. Missing release destinations
are rejected before worker launch. Those regression fixtures may explicitly select their own development runtime;
the template clone campaign itself never uses a development override.

`bash scripts/check.sh` remains the bounded starter pairing check; `check-abc` is a
separate outer gate so per-task verification cannot recursively start the campaign.
The source smoke stays open. Temporary repositories are removed after assertions;
repository completion evidence captures the printed results. The earlier live
sample remains separately attributed at the link above; neither proof asserts
hosted deployment access, provider identity attestation or automatic conflict repair.


## Reproduce guided first-release onboarding

Run `bash scripts/test-guided-onboarding.sh` or `make check-guided` against the
committed product tree with the exact pinned runtime. The test clones that tree,
rejects stale pin/docs metadata, proves that unanswered and answered previews are
read-only, applies the generated settings, and imports the exact execution brief
through the real CLI. It checks that source tasks, claims and release profiles do
not become new-project authority.

The first task starts open with pending outcomes and correct product/version/
changelog scope. A deterministic native CLI double supplies build and critic
responses; **no model calls are made**. The actual controller delivers v1.2.0 to a
disposable local Git remote, checks raw verification and release readback, and
cleans the one owned task worktree. The source contract remains unchanged.
`check-guided` and `check-abc` are separate outer gates to avoid recursion in
per-task checks.

The stack's release-pairing manifest records each release's already immutable
baseline template. This template's README block records its current stack pin and
resolved runtime commit. Those are separate relationships: publishing a newer
template does not rewrite an older stack release's historical baseline.
