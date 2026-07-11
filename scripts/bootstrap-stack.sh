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
  git clone "$STACK_REMOTE" "$GO_STACK"
else
  git -C "$GO_STACK" fetch --quiet origin main || true
fi

if [ ! -f "$GO_STACK/cli/go.py" ]; then
  echo "go-workflow-stack CLI not found at $GO_STACK/cli/go.py" >&2
  exit 1
fi

printf '%s\n' "$GO_STACK"
