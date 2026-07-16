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

STATUS="$("$ROOT/go" status "$ROOT" --json)"
python3 -c 'import json,sys; p=json.load(sys.stdin); assert p["setup_required"] and p["next"] is None' <<<"$STATUS"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SOURCE="$TMP/source"
REMOTE="$TMP/stack.git"
REMOTE_B="$TMP/stack-b.git"
CHECKOUT="$TMP/checkout"
PROJECT="$TMP/project"
SIBLING="$TMP/go-workflow-stack"
CACHE_ROOT="$TMP/cache"
mkdir -p "$SOURCE/cli"
git -C "$SOURCE" init -q -b main
printf 'STACK_VERSION = "9.9.9"\n' >"$SOURCE/cli/go.py"
git -C "$SOURCE" add cli/go.py
git -C "$SOURCE" -c user.name=Template -c user.email=template@example.com commit -q -m pinned
PIN="$(git -C "$SOURCE" rev-parse HEAD)"
git -C "$SOURCE" -c user.name=Template -c user.email=template@example.com tag -a v9.9.9 -m release
git clone --bare -q "$SOURCE" "$REMOTE"
mkdir -p "$PROJECT/scripts" "$PROJECT/.go"
cp "$ROOT/scripts/bootstrap-stack.sh" "$PROJECT/scripts/bootstrap-stack.sh"
python3 - "$ROOT/.go/project.json" "$PROJECT/.go/project.json" "$PIN" <<'PY'
import json
import sys

project = json.load(open(sys.argv[1], encoding="utf-8"))
project["required_stack_version"] = "9.9.9"
project["stack_ref"] = "v9.9.9"
with open(sys.argv[2], "w", encoding="utf-8") as handle:
    json.dump(project, handle, indent=2)
    handle.write("\n")
PY
GO_STACK="$CHECKOUT" GO_STACK_REMOTE="$REMOTE" bash "$PROJECT/scripts/bootstrap-stack.sh" >/dev/null
test "$(git -C "$CHECKOUT" rev-parse HEAD)" = "$PIN"

git clone -q "$SOURCE" "$SIBLING"
printf 'development\n' >"$SIBLING/DEVELOPMENT.md"
git -C "$SIBLING" add DEVELOPMENT.md
git -C "$SIBLING" -c user.name=Template -c user.email=template@example.com commit -q -m development
DEV_HEAD="$(git -C "$SIBLING" rev-parse HEAD)"
DEFAULT_CHECKOUT="$(env -u GO_STACK XDG_CACHE_HOME="$CACHE_ROOT" GO_STACK_REMOTE="$REMOTE" bash "$PROJECT/scripts/bootstrap-stack.sh")"
test "$DEFAULT_CHECKOUT" = "$CACHE_ROOT/go-workflow-stack/v9.9.9"
test "$(git -C "$SIBLING" branch --show-current)" = main
test "$(git -C "$SIBLING" rev-parse HEAD)" = "$DEV_HEAD"
test "$(git -C "$DEFAULT_CHECKOUT" rev-parse HEAD)" = "$PIN"
test "$(git -C "$DEFAULT_CHECKOUT" cat-file -t v9.9.9)" = tag

git clone --bare -q "$SIBLING" "$REMOTE_B"
if env -u GO_STACK XDG_CACHE_HOME="$CACHE_ROOT" GO_STACK_REMOTE="$REMOTE_B" bash "$PROJECT/scripts/bootstrap-stack.sh" >"$TMP/wrong-remote.out" 2>"$TMP/wrong-remote.err"; then
  echo "managed cache unexpectedly accepted a different remote" >&2
  exit 1
fi
grep -q "cache origin does not match GO_STACK_REMOTE" "$TMP/wrong-remote.err"

echo "template contract tests: ok"
