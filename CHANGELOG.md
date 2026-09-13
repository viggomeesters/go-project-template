# Changelog

## 0.3.15 — explicit lifecycle onboarding and linked runtimes

- Pin the released v0.3.26 stack with real ordered model/task release proof.
- Add explicit lifecycle, model and complete task examples without active defaults.
- Accept valid linked runtime worktrees; reject mismatched or dirty explicit runtimes
  without resetting user work, and honor an explicit Python executable.
- Keep the starter smoke reusable and source maintenance non-executable in clones.

## Unreleased

## 0.3.11 - 2026-08-11

- Pin the template to annotated stack release `v0.3.11`, resolved exactly to `8155f449f78ea57af38b407c30c8ad3ad56e0e48`.
- Make restricted stakeholder delivery automatic for substantial approved agent tasks, with explicit policy overrides, immutable versions, fail-closed rollback, and per-epic concurrency serialization.

## 0.3.10 - 2026-08-11

- Pin the template to annotated stack release `v0.3.10`, resolved exactly to `fa451abc9f4f44174d4cfb14f42767fcd1391cee`.
- Expose deterministic standalone stakeholder delivery HTML, strict manifest validation, restricted-by-default disclosure, immutable superseding releases, and fail-closed publication through the pinned stack runtime.

## 0.3.9 - 2026-08-01

- Document one public `Go` command with plan, task-id, loop-budget, and internal routing semantics for every repo created from the template.
- Pin the template to annotated stack release `v0.3.9` at `0448d2ea727ffe3f318484cbf97de6b563899557`, preserving durable recommendation promotion and same-invocation execution.

## 0.3.8 - 2026-07-28

- Pin the template to annotated stack release `v0.3.8`, resolved exactly to `c30e11d580167a1b088cd84a5487ae02cb904449`.
- Let fresh projects inherit the stack's capacity planning, separate work/review lifecycle, and attributed finish-evidence contract.
- Use `bash scripts/validate-go.sh` as the bounded per-task project verification; keep `scripts/check-linux.sh` as the outer template/pairing gate to avoid recursive auto verification.
- Mechanically execute the reusable first-run task in an isolated fresh copy and assert v0.3.8 work/review state plus runtime, billing, usage, and review-attributed finish evidence.

## 0.3.4 - 2026-07-16

- Pin the template to annotated stack release `v0.3.4`, resolved exactly to `e3fc0adb352eeda9a69e04890486db1eb49482b7`.
- Allow a package-installed stack runtime to prove the immutable tag through exact PEP 610 VCS provenance from the official GitHub repository, without `GO_STACK_ALLOW_DEV=1`.
- Preserve the transactional before/after project contract in the generated stack-update rollback record.
- Isolate the template-managed checkout under the user cache so local checks never detach a sibling stack development clone.

## 0.3.3 - 2026-07-16

- Pin the template to annotated stack release `v0.3.3`, resolved exactly to `697f89baa8d43105a715b662c6f3b46d37ba8a4b`.
- Adopt native Hermes prompt-capability detection and the validated WSL proof without requiring `GO_STACK_ALLOW_DEV=1`.
- Preserve the transactional before/after project contract in the generated stack-update rollback record.

## 0.3.2 - 2026-07-16

- Pin the template to the release-safe v0.3.2 doctor-fixture hotfix.
- Record the exact resolved stack commit and rollback state through `go stack update`.

## 0.3.1 - 2026-07-15

- Pin the template to the exact v0.3.1 stack runtime contract.
- Reject `GO_STACK_REF` so `.go/project.json` remains the only stack-ref source of truth.
- Normalize `.go` JSON and JSONL contracts to non-executable file modes.

## 0.2.0 - 2026-07-14

- Added an executable project-local `./go` launcher and WSL/Hermes usage flow.
- Added minimum stack-version compatibility and Linux pairing CI.
- Hardened stack bootstrap updates to fast-forward clean `main` and stop on dirty or diverged state.
- Added clone-local validation and project-specific template application guidance.

## 0.1.0 - 2026-07-03

- Initial public scaffold for Go Project Template.
- Added public README, MIT license, security/support/contributing docs, issue templates, and local validation.
