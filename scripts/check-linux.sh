#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK="$(GO_STACK="${GO_STACK:-}" bash "$ROOT/scripts/bootstrap-stack.sh")"

if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; raise SystemExit(sys.version_info < (3, 11))'; then
  PYTHON="python3"
elif command -v uv >/dev/null 2>&1; then
  PYTHON="uv run --python '>=3.11' --no-project python"
else
  echo "Python 3.11+ required; install Python 3.11+ or uv." >&2
  exit 2
fi

GO_STACK="$STACK" make -C "$ROOT" PYTHON="$PYTHON" check
GO_STACK="$STACK" bash "$ROOT/scripts/test-template.sh"

if [ "${GO_REQUIRE_LIVE_HERMES:-0}" = "1" ]; then
  GO_STACK="$STACK" "$ROOT/go" doctor "$ROOT" --platform wsl --agent hermes
fi

echo "local template Linux/WSL verification: ok"
