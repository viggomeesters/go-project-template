#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK="${GO_STACK:-}"

if [ -z "$STACK" ] || [ ! -f "$STACK/cli/go.py" ]; then
  if [ -x "$REPO_ROOT/scripts/bootstrap-stack.sh" ]; then
    STACK="$(GO_STACK="$STACK" bash "$REPO_ROOT/scripts/bootstrap-stack.sh")"
  elif [ -f "$REPO_ROOT/../go-workflow-stack/cli/go.py" ]; then
    STACK="$REPO_ROOT/../go-workflow-stack"
  fi
fi

if [ -z "$STACK" ] || [ ! -f "$STACK/cli/go.py" ]; then
  echo "go-workflow-stack not found; set GO_STACK or clone it beside this repository" >&2
  exit 2
fi

export GO_STACK="$STACK"
exec python3 "$STACK/cli/go.py" "$@"
