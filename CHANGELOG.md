# Changelog

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
