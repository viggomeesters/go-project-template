# Repository-local Go workflow

This is the public starter for the new JSON-first `.go/` workflow. Inside a repository created from this template, `.go/` is the source of truth; do not require `.go-workflow/config.yaml` and do not route through the legacy Life OS pipeline.

`Go` is the single public repository-work command. `Go plan`, `Go T123`, and
`Go loop 2h` are modifiers; stack commands such as `auto`, `go-loop`, task
creation, claim, and finish are internal primitives.

When the user says `Go`, uses a Go modifier, says `Next`, or asks to continue autonomously:

0. Before route, task creation, claim, or product edits, prove stack freshness with a trusted current `go-workflow-stack` checkout. Fetch its annotated tags, run `python3 /path/to/go-workflow-stack/cli/go.py stack update . --latest --stack-repo /path/to/go-workflow-stack --json`, apply only when `up_to_date=false`, then run `./go doctor . --platform <platform> --agent <agent-name> --json`. Require `exact_ref=true`, `compatible=true`, and `ready=true`. Stop if the trusted checkout, immutable tag, update, or doctor proof is unavailable; never substitute mutable `main`, an old global runtime, or `GO_STACK_ALLOW_DEV=1`.
1. Locate the pinned stack through the project-local `./go` launcher after the freshness preflight; set `GO_STACK` only to an exact matching immutable checkout.
2. Read `.go/vision.json`, `.go/architecture-principles.json`, `.go/hierarchy.json`, and the selected task JSON.
3. Run `bash scripts/validate-go.sh`, `./go status . --json`, and `./go router . --command go --intent "$PROMPT_TEXT" --json`. Use `selected_route` and the authority fields from the pinned runtime. Announce one `Route: <advice|wayfinder|vision|plan|task|now|goal|loop>` line and continue without asking for another Go command.
4. If this is still a copied template contract, use the read-only `./go onboarding plan . --json` to collect missing project choices. Reuse explicit session choices, review generated settings and the first execution brief, then customize only the new copy and import that brief through the steps in `docs/abc-onboarding.md`. Never infer model, release destination or push/deployment authority.
5. Create or repair a concrete task before implementation, then execute only its allowed modify scope.
6. `Go plan` stops before implementation. Otherwise verify, critic/recheck, repair, record evidence, and continue until done, a repository gate, or budget exhaustion.

For substantial advice, do not persist the full response. Persist only a
validated compact execution brief with `./go recommendation create . --brief
<temporary-json>`. Explicit `alleen advies`/`read-only` uses `--read-only` and
must not mutate `.go`. A later bare `Go` or **Sent as goal** consumes
`.go/recommendations/pending.json`, archives it, creates semantic tasks, and
continues execution in the same invocation. Every R# outcome requires a
terminal disposition and non-empty evidence before finish. Internally pass
`--authority-source sent_as_goal` for Codex **Sent as goal** and
`--authority-source imperative` for a continuation such as “aan de slag”; bare
Go uses the default `go` source.

Run `bash scripts/check.sh` for the stack/template pairing check. Preserve unrelated user changes and do not push without explicit authorization.

## GitHub Actions boundary

GitHub Actions are off limits. Do not create, edit, enable, trigger, dispatch, inspect, wait for, or use GitHub Actions workflows/checks as verification evidence. Existing files under `.github/workflows/` are not authorization to interact with GitHub Actions. Use local checks, a local Linux container, or another explicitly approved verification route instead.

## Source maintenance and project onboarding

When maintaining the `go-project-template` source, keep `project_mode: template`. Step 4 applies to a copied
starter being customized into a new project; it does not authorize turning this
source repository into an app. Follow `docs/abc-onboarding.md` for explicit settings.
No execution_defaults, user model/account, publication command or production target
is selected by the starter. The named source maintenance Git verifier and dependency
mapping are source metadata; guided adoption or `spike` replaces inherited `.go` during customization.

Keep active/pending source maintenance tasks out of published starter trees. Publish
completed maintenance records and raw proof as non-executable history in `.go/evidence/`.
Retain canonical records while dependent source work still needs them; archive the
completed source queue only after dependent work and its proof are complete. Preserve
all source evidence and the reusable open smoke task. A copied project must not
inherit source maintenance claims, run authority or runnable tasks.

For product intake, include actual version/changelog paths in task modify scope and
use real project checks. Workers report R# evidence; the canonical controller owns
outcome writes, publication/readback and final completion. A critic before publication
judges candidate readiness and leaves downstream shipping proof pending. Keep one
owned worktree across build/critic/repair; do not create one per model change.

<!-- go-workflow:agents-gateway:v1:start -->
## Repository-local Go workflow gateway

This repository uses `.go/` as its project workflow source of truth. Keep repository-specific instructions outside this managed block; they remain binding.

When the user invokes `Go`, `Go plan`, `Go <task-id>`, `Go loop`, or asks to continue autonomously:

1. Run the immutable stack-freshness preflight required by the pinned `.go/project.json` before routing or product edits.
2. Read `.go/vision.json`, `.go/architecture-principles.json`, `.go/hierarchy.json`, and the selected task.
3. Run the repository-local `validate`, `status`, and `router` commands, then announce `Route: <selected_route>`.
4. Create or repair a concrete `.go` task before changing product files. Execute one task at a time and stay within its `scope.modify` boundary.
5. Record content-bound verification evidence, run the required critic/recheck, repair blocking findings, and satisfy finish plus any required release evidence.
6. Continue through remaining in-scope work until the goal is met, a declared budget is exhausted, or a real repository gate blocks progress. Never call an empty queue `done` without auditing the original outcomes.

Do not redirect repository workflow state to a hidden central queue or retired vault. Nested `AGENTS.md` files may add directory-specific obligations, but they do not replace the root gateway or `.go` source of truth.
<!-- go-workflow:agents-gateway:v1:end -->
