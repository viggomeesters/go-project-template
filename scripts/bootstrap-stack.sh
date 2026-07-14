#!/usr/bin/env bash
set -euo pipefail

# Ensure a fresh go-project-template clone can run `bash scripts/check.sh`
# without the user manually cloning the stack first.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_STACK="$(cd "$REPO_ROOT/.." && pwd)/go-workflow-stack"
GO_STACK="${GO_STACK:-$DEFAULT_STACK}"
STACK_REMOTE="${GO_STACK_REMOTE:-https://github.com/viggomeesters/go-workflow-stack.git}"

if [ ! -d "$GO_STACK/.git" ]; then
  mkdir -p "$(dirname "$GO_STACK")"
  git clone --branch main "$STACK_REMOTE" "$GO_STACK"
else
  if [ -n "$(git -C "$GO_STACK" status --porcelain)" ]; then
    echo "go-workflow-stack checkout is dirty; commit, stash, or clean it before bootstrap updates" >&2
    exit 3
  fi
  BRANCH="$(git -C "$GO_STACK" branch --show-current)"
  if [ "$BRANCH" != "main" ]; then
    echo "go-workflow-stack checkout must be on main for automatic bootstrap updates (current: ${BRANCH:-detached})" >&2
    exit 3
  fi
  git -C "$GO_STACK" fetch --quiet origin main
  if ! git -C "$GO_STACK" merge-base --is-ancestor HEAD origin/main; then
    echo "go-workflow-stack main has diverged from origin/main; reconcile it explicitly before continuing" >&2
    exit 4
  fi
  git -C "$GO_STACK" merge --ff-only --quiet origin/main
fi

if [ ! -f "$GO_STACK/cli/go.py" ]; then
  echo "go-workflow-stack CLI not found at $GO_STACK/cli/go.py" >&2
  exit 1
fi

printf '%s\n' "$GO_STACK"
