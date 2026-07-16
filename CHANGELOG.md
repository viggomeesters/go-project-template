# Changelog

## 0.3.4 - 2026-07-16

- Pin the template to annotated stack release `v0.3.4`, resolved exactly to `e3fc0adb352eeda9a69e04890486db1eb49482b7`.
- Allow a package-installed stack runtime to prove the immutable tag through exact PEP 610 VCS provenance from the official GitHub repository, without `GO_STACK_ALLOW_DEV=1`.
- Preserve the transactional before/after project contract in the generated stack-update rollback record.

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
