#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GO_STACK="$(GO_STACK="${GO_STACK:-}" bash "$SCRIPT_DIR/bootstrap-stack.sh")"
export GO_STACK
PYTHON="${PYTHON:-python3}"
make -C "$REPO_ROOT" check
"$PYTHON" "$GO_STACK/cli/go.py" architecture validate "$REPO_ROOT" --json >"${TMPDIR:-/tmp}/go-template-architecture-validate.json"
"$PYTHON" "$GO_STACK/cli/go.py" architecture readback "$REPO_ROOT" --task-id task-schema-smoke --json >"${TMPDIR:-/tmp}/go-template-architecture-readback.json"
"$PYTHON" "$GO_STACK/cli/go.py" architecture status "$REPO_ROOT" --json >"${TMPDIR:-/tmp}/go-template-architecture-status.json"
"$PYTHON" - "${TMPDIR:-/tmp}/go-template-architecture-readback.json" "${TMPDIR:-/tmp}/go-template-architecture-status.json" <<'PY'
import json
import sys

readback = json.load(open(sys.argv[1], encoding="utf-8"))
status = json.load(open(sys.argv[2], encoding="utf-8"))
assert readback["applicable_architecture"]["classification"]["impact"] == "none"
assert readback["status"]["briefs"]["accepted"] >= 1
assert readback["status"]["briefs"]["draft"] == 0
assert status["open_deviations"] == 0 and status["active_waivers"] == 0
PY

echo "architecture lane template contract: ok"

TMP_REPO="$(mktemp -d "${TMPDIR:-/tmp}/go-advice-template-check.XXXXXX")"
trap 'rm -rf "$TMP_REPO"' EXIT
git init -q "$TMP_REPO"
cd "$TMP_REPO"
"$PYTHON" "$GO_STACK/cli/go.py" adopt "$TMP_REPO" --project-id advice-template-check --name "Advice Template Check" >/dev/null
"$PYTHON" - "$TMP_REPO/brief.json" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

recommendation = "Keep the compact recommendation durable until bare Go promotes it."
brief = {
    "schema": "go-workflow.execution-brief.v1",
    "destination": "A resumable recommendation handoff.",
    "problem": "Chat context is not durable.",
    "chosen_approach": recommendation,
    "non_goals": [],
    "source": {
        "recommendation": recommendation,
        "sha256": hashlib.sha256(recommendation.encode()).hexdigest(),
        "source_ref": "template:local-check",
    },
    "work_units": [{
        "id": "template-advice-proof",
        "summary": "Prove recommendation promotion",
        "scope": {"read": ["README.md"], "modify": []},
        "execution_mode": "mechanical",
        "acceptance": ["The compact recommendation becomes a task."],
        "verification": ["true"],
    }],
}
Path(sys.argv[1]).write_text(json.dumps(brief), encoding="utf-8")
PY
"$PYTHON" "$GO_STACK/cli/go.py" recommendation create "$TMP_REPO" --brief "$TMP_REPO/brief.json" --authority advice --authority-source question >/dev/null
rm "$TMP_REPO/brief.json"
"$PYTHON" "$GO_STACK/cli/go.py" go "$TMP_REPO" --write --json >/dev/null
test -f "$TMP_REPO/.go/recommendations/applied/recommendation-"*.json
test -f "$TMP_REPO/.go/tasks/open/template-advice-proof.json"
"$PYTHON" "$GO_STACK/cli/go.py" validate "$TMP_REPO" >/dev/null
echo "advice-to-outcome template contract: ok"
