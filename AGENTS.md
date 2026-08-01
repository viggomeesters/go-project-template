# Repository-local Go workflow

This is the public starter for the new JSON-first `.go/` workflow. Inside a repository created from this template, `.go/` is the source of truth; do not require `.go-workflow/config.yaml` and do not route through the legacy Life OS pipeline.

`Go` is the single public repository-work command. `Go plan`, `Go T123`, and
`Go loop 2h` are modifiers; stack commands such as `auto`, `go-loop`, task
creation, claim, and finish are internal primitives.

When the user says `Go`, uses a Go modifier, says `Next`, or asks to continue autonomously:

1. Locate the stack through the project-local `./go` launcher; set `GO_STACK` only to override discovery.
2. Read `.go/vision.json`, `.go/architecture-principles.json`, `.go/hierarchy.json`, and the selected task JSON.
3. Run `bash scripts/validate-go.sh`, `./go status . --json`, and `./go router . --command go --intent "$PROMPT_TEXT" --json`. Use `selected_route` and the authority fields from the pinned runtime. Announce one `Route: <advice|wayfinder|vision|plan|task|now|goal|loop>` line and continue without asking for another Go command.
4. If this is still a copied template contract, customize it first with `./go spike . --brief "$PROJECT_INTENT"`.
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
