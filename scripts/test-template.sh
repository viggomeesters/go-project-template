#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test ! -d "$ROOT/.github/workflows"
python3 - "$ROOT/.go/project.json" <<'PY'
import json
import sys

project = json.load(open(sys.argv[1], encoding="utf-8"))
assert project["project_mode"] == "template"
assert project["stack_ref"].startswith("v")
PY

STATUS="$(GO_STACK="${GO_STACK:-$ROOT/../go-workflow-stack}" "$ROOT/go" status "$ROOT" --json)"
python3 -c 'import json,sys; p=json.load(sys.stdin); assert p["setup_required"] and p["next"] is None' <<<"$STATUS"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SOURCE="$TMP/source"
REMOTE="$TMP/stack.git"
CHECKOUT="$TMP/checkout"
mkdir -p "$SOURCE/cli"
git -C "$SOURCE" init -q -b main
printf 'STACK_VERSION = "9.9.9"\n' >"$SOURCE/cli/go.py"
git -C "$SOURCE" add cli/go.py
git -C "$SOURCE" -c user.name=Template -c user.email=template@example.com commit -q -m pinned
PIN="$(git -C "$SOURCE" rev-parse HEAD)"
git clone --bare -q "$SOURCE" "$REMOTE"
GO_STACK="$CHECKOUT" GO_STACK_REMOTE="$REMOTE" GO_STACK_REF="$PIN" bash "$ROOT/scripts/bootstrap-stack.sh" >/dev/null
test "$(git -C "$CHECKOUT" rev-parse HEAD)" = "$PIN"

echo "template contract tests: ok"
