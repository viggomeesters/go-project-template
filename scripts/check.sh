#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ -z "${GO_STACK:-}" ] || [ ! -f "$GO_STACK/cli/go.py" ]; then
  GO_STACK="$(GO_STACK="${GO_STACK:-}" bash "$SCRIPT_DIR/bootstrap-stack.sh")"
fi
export GO_STACK
make -C "$REPO_ROOT" check
