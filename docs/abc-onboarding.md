# Explicit A/B/C onboarding

This starter release uses stack **v0.3.26**, commit
`b2d235610691eead011cc738f278887a99e4bbe0`. It remains `project_mode: template`
and has no `execution_defaults`. `task-schema-smoke` is a reusable mechanical
contract check; it does not select a model or represent an app release.

A new project must choose its own values before product execution. The JSON files
under `examples/abc/` are schema-valid planning inputs. `CHOOSE_*` and
`CUSTOMIZED_PROJECT_ID` are placeholders, not working defaults. An unknown model
or missing command/remote is supposed to block execution.

| Input to collect | Where it belongs |
| --- | --- |
| Observable app outcome and real checks | Task acceptance, `verification`, and pending R# coverage |
| Supported model ID and reasoning effort | `execution_defaults.model`, or a task execution-contract override |
| Optional separate critic model/effort | `critic_model`; existing run selections remain frozen |
| Existing base branch and workspace policy | `workspace.base_branch`, `task_worktree`, `repo_local_single_writer` |
| Actual text/JSON product version source and bump | Named release profile `publication.version` and `bump` |
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

The controller currently prepares **text or JSON** version sources. A different
version format requires an explicitly supported project arrangement; do not pretend
a TOML/package source was updated by the example text-file profile.

## Customize a copy, then prepare its tasks

Use Python 3.11 or newer, Git and the project's selected agent runtime. For example,
`uv run --no-project --python 3.12 ./go ...` supplies a compatible Python. `PYTHON`
may name one Python executable; it is not a shell command string.

In a new copied starter, let Go collect the inputs above and review the filled
settings document. The internal customization command is:

```bash
./go spike . --project-id my-project --name "My Project" \
  --brief "The agreed product outcome" --lifecycle-settings /path/to/settings.json
```

**Customization replaces the inherited `.go`** with the new project contract. Use
it on the new copy, not on the maintained template source or an existing app with
its own workflow history. Source maintenance profiles, dependency mapping, claims,
architecture decisions and old tasks are not the new project's authority.

Run **Go plan** to refine the generated tasks before executing them. Scaffolding
preserves its scope presets: it cannot infer your version files or product checks.
Every product task must include the actual version/changelog paths in modify scope,
real verification and observable acceptance. Reuse/refine matching generated tasks;
do not create duplicate work or describe a scaffold check as a product release.
`task.example.json` shows a complete parameterized product task and scope.

For a new task, the agent can use the ordinary intake with configured defaults:

```bash
./go task create . --id deliver-release --summary "Deliver the agreed app change" \
  --epic delivery --execution-mode agent \
  --read '.go/**' --read app.py --read 'tests/**' \
  --modify app.py --modify 'tests/**' --modify VERSION --modify CHANGELOG.md \
  --acceptance "The agreed observable behavior is present" \
  --verification "python3 -m pytest -q"
```

Those paths/checks are illustrative; use the real project values. An optional
`--execution-contract /path/to/model-override.json` selects another task model or
critic profile. Availability and effort support are checked before native launch.
The runtime enforces requested arguments; effective provider identity remains
unconfirmed unless separately attested. No in-flight profile edit or mid-turn
hot switch is supported.

For an existing project's legacy tasks, use an explicit preview first:

```bash
./go migrate . --lifecycle --config /path/to/settings.json --json
./go migrate . --lifecycle --config /path/to/settings.json --apply --json
```

Adoption requires quiescent state, preserves existing task overrides and history,
and does not grant execution authority. Preserve the journal for supported resume
or rollback; changed history blocks unsafe rollback. A stack pin update alone does
not adopt model/release defaults.

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
It used a disposable development candidate whose 53 runtime file hashes match the
release. It proves those native local Git releases, not hosted deployment access or
general model quality. Template v0.3.16 adds the complete fresh clone/linked-worktree campaign below.


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
