#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

python3 - "$REPO_ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
project = json.loads((root / ".go" / "project.json").read_text(encoding="utf-8"))
assert project["required_stack_version"] == "0.3.13"
assert project["stack_ref"] == "v0.3.13"
architecture_brief = json.loads((root / ".go" / "architecture" / "briefs" / "project-boundary.json").read_text(encoding="utf-8"))
assert architecture_brief["status"] == "accepted"
assert architecture_brief["quality_attributes"][0]["threshold"] == 0
assert (root / ".go" / "architecture" / "events.jsonl").is_file()
surfaces = "\n".join(
    (root / name).read_text(encoding="utf-8")
    for name in ("AGENTS.md", "README.md")
)
for required in (
    "stack update . --latest",
    "before route",
    "exact_ref=true",
    "compatible=true",
    "ready=true",
    "GO_STACK_ALLOW_DEV=1",
):
    assert required in surfaces, required
PY

exec "$REPO_ROOT/go" validate "$REPO_ROOT"
