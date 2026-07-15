#!/usr/bin/env bash
set -euo pipefail

# Ensure a fresh go-project-template clone can run `bash scripts/check.sh`
# without the user manually cloning the stack first.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEFAULT_STACK="$(cd "$REPO_ROOT/.." && pwd)/go-workflow-stack"
EXPLICIT_STACK=0
if [ -n "${GO_STACK:-}" ]; then
  EXPLICIT_STACK=1
else
  GO_STACK="$DEFAULT_STACK"
fi
STACK_REMOTE="${GO_STACK_REMOTE:-https://github.com/viggomeesters/go-workflow-stack.git}"
STACK_REF="${GO_STACK_REF:-$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["stack_ref"])' "$REPO_ROOT/.go/project.json")}"

runtime_ref() {
  local version
  version="$(sed -n 's/^STACK_VERSION = "\([^"]*\)"/\1/p' "$1/cli/go.py" | head -1)"
  [ -n "$version" ] && printf 'v%s\n' "$version"
}

runtime_matches() {
  local checkout="$1"
  if [[ "$STACK_REF" =~ ^[0-9a-f]{40}$ ]]; then
    [ "$(git -C "$checkout" rev-parse HEAD 2>/dev/null || true)" = "$STACK_REF" ]
  else
    [ "$(runtime_ref "$checkout")" = "$STACK_REF" ]
  fi
}

if [ ! -d "$GO_STACK/.git" ]; then
  mkdir -p "$(dirname "$GO_STACK")"
  if [[ "$STACK_REF" =~ ^[0-9a-f]{40}$ ]]; then
    git clone --no-checkout "$STACK_REMOTE" "$GO_STACK"
    git -C "$GO_STACK" checkout --detach --quiet "$STACK_REF"
  else
    git clone --branch "$STACK_REF" --depth 1 "$STACK_REMOTE" "$GO_STACK"
  fi
elif [ "$EXPLICIT_STACK" = "1" ]; then
  if ! runtime_matches "$GO_STACK"; then
    echo "explicit GO_STACK does not provide pinned runtime $STACK_REF" >&2
    exit 4
  fi
else
  if [ -n "$(git -C "$GO_STACK" status --porcelain)" ]; then
    echo "go-workflow-stack checkout is dirty; commit, stash, or clean it before bootstrap updates" >&2
    exit 3
  fi
  if ! runtime_matches "$GO_STACK"; then
    git -C "$GO_STACK" fetch --quiet --depth 1 origin "$STACK_REF"
    git -C "$GO_STACK" checkout --detach --quiet FETCH_HEAD
  fi
fi

if [ ! -f "$GO_STACK/cli/go.py" ]; then
  echo "go-workflow-stack CLI not found at $GO_STACK/cli/go.py" >&2
  exit 1
fi

if ! runtime_matches "$GO_STACK"; then
  echo "go-workflow-stack runtime ref mismatch: expected $STACK_REF" >&2
  exit 4
fi

printf '%s\n' "$GO_STACK"
