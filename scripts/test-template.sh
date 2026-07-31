#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test ! -d "$ROOT/.github/workflows"
grep -Fq 'single public repository-work command' "$ROOT/AGENTS.md"
grep -Fq 'single public repository-work command' "$ROOT/README.md"
grep -Fq '`Go plan ' "$ROOT/README.md"
grep -Fq '`Go loop 2h ' "$ROOT/README.md"
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
FRESH="$TMP/fresh-project"
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

# Exercise the reusable example task in an isolated fresh project while keeping
# the source template's open fixture untouched.
python3 - "$ROOT" "$FRESH" <<'PY'
import json
import shutil
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
shutil.copytree(source, target, ignore=shutil.ignore_patterns(".git"))

tasks_root = target / ".go" / "tasks"
for state in ("active", "blocked", "done"):
    for path in (tasks_root / state).glob("*.json"):
        path.unlink()
for path in (tasks_root / "open").glob("*.json"):
    if path.name != "task-schema-smoke.json":
        path.unlink()

hierarchy_path = target / ".go" / "hierarchy.json"
hierarchy = json.loads(hierarchy_path.read_text(encoding="utf-8"))
for epic in hierarchy["epics"]:
    epic["tasks"] = []
    for feature in epic.get("features", []):
        feature["tasks"] = [
            task_id for task_id in feature.get("tasks", [])
            if task_id == "task-schema-smoke"
        ]
hierarchy_path.write_text(json.dumps(hierarchy, indent=2) + "\n", encoding="utf-8")
PY

git -C "$FRESH" init -q -b main
git -C "$FRESH" add .
git -C "$FRESH" -c user.name=Template -c user.email=template@example.com commit -q -m fresh
test -f "$ROOT/.go/tasks/open/task-schema-smoke.json"
GO_STACK="${GO_STACK:-}" "$FRESH/go" auto "$FRESH" \
  --max-tasks 1 --execute --agent template-contract --json >"$TMP/auto-result.json"
python3 - "$TMP/auto-result.json" "$FRESH/.go/tasks/done/task-schema-smoke.json" <<'PY'
import json
import sys

result = json.load(open(sys.argv[1], encoding="utf-8"))
task = json.load(open(sys.argv[2], encoding="utf-8"))

assert result["schema"] == "go-workflow.auto-run-result.v1"
assert result["status"] == "done"
assert result["completed_tasks"] == ["task-schema-smoke"]
assert result["completion_audit"]["contract_valid"] is True
assert task["status"] == "done"
assert task["work_status"] == "completed"
assert task["review_status"] == "approved"

evidence = task["evidence"][-1]
assert evidence["schema"] == "go-workflow.finish-evidence.v1"
assert evidence["verification"]["command"]
assert evidence["verification"]["result"]
assert evidence["runtime"]["agent"] == "template-contract"
assert evidence["runtime"]["runtime"] == "go-auto"
assert evidence["runtime"]["billing_mode"]
assert evidence["usage"]["schema"] == "go-workflow.usage-attribution.v1"
assert evidence["usage"]["cost_label"] == "api_equivalent_not_invoice_cost"
assert evidence["review"]["outcome"] == "passed"
PY
test -f "$ROOT/.go/tasks/open/task-schema-smoke.json"

echo "template contract tests: ok"
