#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK="$(GO_STACK="${GO_STACK:-}" bash "$ROOT/scripts/bootstrap-stack.sh")"
export GO_STACK="$STACK" PYTHONDONTWRITEBYTECODE=1
unset GO_STACK_ALLOW_DEV

"${PYTHON:-python3}" - "$ROOT" "$STACK" <<'PY'
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
stack = Path(sys.argv[2])
env = {
    **os.environ,
    "PYTHON": sys.executable,
    "PYTHONDONTWRITEBYTECODE": "1",
    "GO_STACK": str(stack),
    "PATH": str(Path(sys.executable).parent) + os.pathsep + os.environ["PATH"],
}
env.pop("GO_STACK_ALLOW_DEV", None)


def call(args, cwd, *, run_env=env, ok=True, timeout=900):
    result = subprocess.run(
        list(map(str, args)), cwd=cwd, env=run_env, text=True,
        capture_output=True, timeout=timeout,
    )
    if ok:
        assert result.returncode == 0, result.stdout + result.stderr
    return result


def git(repo, *args):
    return call(["git", "-C", repo, *args], root).stdout.strip()


def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def write(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def tree(path):
    return {
        str(item.relative_to(path)): hashlib.sha256(item.read_bytes()).hexdigest()
        for item in Path(path).rglob("*")
        if item.is_file() and ".git" not in item.parts
    }


project = read(root / ".go/project.json")
assert project["project_mode"] == "template"
assert "execution_defaults" not in project
pin = project["stack_ref"]
runtime_commit = git(stack, "rev-parse", pin + "^{commit}")
assert git(stack, "rev-parse", "HEAD") == runtime_commit
assert git(stack, "cat-file", "-t", "refs/tags/" + pin) == "tag"
source_state = tree(root / ".go")

choices_example = read(root / "docs/examples/autonomy-campaign-answers.json")
encoded_example = json.dumps(choices_example)
for placeholder in (
    "CHOOSE_GOAL", "CHOOSE_SUPPORTED_MODEL", "CHOOSE_SHARED_WALL_SECONDS",
    "CHOOSE_RELEASE_PROFILE", "CHOOSE_DEPLOYMENT_MODE",
):
    assert placeholder in encoded_example

campaign_spec = importlib.util.spec_from_file_location(
    "autonomy_campaign", stack / "fixtures/autonomy-campaign/campaign.py"
)
assert campaign_spec is not None and campaign_spec.loader is not None
campaign = importlib.util.module_from_spec(campaign_spec)
campaign_spec.loader.exec_module(campaign)

with tempfile.TemporaryDirectory(prefix="go-template-autonomy-") as temporary:
    temp = Path(temporary)
    starter = temp / "starter"
    call(["git", "clone", "--quiet", "--no-hardlinks", root, starter], temp)
    assert sorted(path.stem for path in (starter / ".go/tasks/open").glob("*.json")) == [
        "task-schema-smoke"
    ]
    assert not list((starter / ".go/tasks/active").glob("*.json"))
    assert read(starter / ".go/project.json")["stack_ref"] == pin
    git(starter, "config", "user.name", "Autonomy onboarding fixture")
    git(starter, "config", "user.email", "autonomy-onboarding@example.invalid")
    git(starter, "checkout", "-B", "main")
    (starter / "VERSION").write_text("1.1.0\n", encoding="utf-8")

    before_plan = tree(starter)
    unresolved = read_payload = json.loads(call(
        [starter / "go", "onboarding", "plan", starter, "--json"], starter
    ).stdout)
    assert unresolved["status"] == "needs_configuration"
    assert {"model", "publisher", "verification", "deployment"} <= {
        question["field"] for question in unresolved["questions"]
    }
    assert tree(starter) == before_plan

    answers = read(starter / "examples/abc/onboarding-answers.example.json")
    answers.update(
        model={"id": "gpt-6-astra", "effort": "high"},
        base_branch="main",
        verification=["git diff --check"],
        publisher={"provider": "git-tag", "remote": "origin"},
        version={"path": "VERSION", "format": "text"},
        bump="minor",
        tag_prefix="v",
        changelog="CHANGELOG.md",
        deployment={"mode": "none", "reason": "Disposable local autonomy proof"},
        task={
            "id": "campaign-intake",
            "summary": "Explore the bounded two-release goal",
            "scope": {"read": [".go/**"], "modify": ["alpha.txt", "beta.txt"]},
            "acceptance": ["Both requested outcomes are mapped before execution"],
        },
    )
    answer_path = temp / "answers.json"
    write(answer_path, answers)
    plan = json.loads(call(
        [starter / "go", "onboarding", "plan", starter, "--answers", answer_path, "--json"],
        starter,
    ).stdout)
    assert plan["status"] == "ready" and not plan["questions"]
    assert tree(starter) == before_plan
    settings = temp / "settings.json"
    write(settings, plan["settings"])

    smoke = read(starter / ".go/tasks/open/task-schema-smoke.json")
    call([
        starter / "go", "adopt", starter, "--force",
        "--project-id", "repo-local-spike-fixture",
        "--name", "Template autonomy fixture",
        "--lifecycle-settings", settings,
    ], starter)
    configured = read(starter / ".go/project.json")
    assert configured["project_mode"] == "project"
    assert "dependency_projects" not in configured
    assert not list((starter / ".go/tasks/open").glob("*.json"))
    assert not list((starter / ".go/evidence").glob("*history*"))

    # The released campaign fixture consumes the reusable smoke contract as a
    # seed. Reintroducing it here is fixture setup, not inherited source work.
    smoke["project"] = configured["id"]
    write(starter / ".go/tasks/open/task-schema-smoke.json", smoke)
    seed_root = temp / "seed-root"
    shutil.copytree(
        starter,
        seed_root / "fixtures/minimal",
        ignore=shutil.ignore_patterns(".git", "__pycache__", ".pytest_cache", ".DS_Store"),
    )
    campaign.ROOT = seed_root

    proof = temp / "proof"
    prepared = campaign.setup(proof, runtime=stack)
    contract = read(prepared["contract"])
    assert contract["goal"]["text"] == (
        "Deliver both rough-request outcomes as separate verified local releases."
    )
    assert contract["authority"]["models"] == campaign.PROFILES
    assert contract["authority"]["budget"] == {
        "wall_seconds": 600, "max_tasks": 3, "max_attempts": 6
    }
    assert contract["authority"]["release"] == {
        "profiles": ["local"], "allow_push": True,
        "source_ref": "user:autonomy-fixture",
    }
    assert contract["authority"]["deployment"] == {"targets": [], "source_ref": None}

    binary = temp / "codex"
    binary.write_text("#!" + sys.executable + "\n" + campaign.worker_source(), encoding="utf-8")
    binary.chmod(0o755)
    worker_capture = proof / "worker-calls.jsonl"
    run_env = {
        **env,
        "PATH": str(temp) + os.pathsep + env["PATH"],
        "AUTONOMY_CAMPAIGN_CAPTURE": str(worker_capture),
    }

    invalid = copy.deepcopy(contract)
    invalid["authority"]["release"]["source_ref"] = None
    invalid_path = temp / "campaign-missing-authority.json"
    write(invalid_path, invalid)
    refused = campaign.run({**prepared, "contract": invalid_path}, env=run_env)
    assert refused["returncode"] != 0
    assert not worker_capture.exists(), "missing release authority reached a worker"

    result = campaign.run(prepared, env=run_env)
    assert result["returncode"] == 0, result["stdout"] + result["stderr"]
    payload = result["result"]
    assert payload["status"] == "goal_verified" and payload["goal_verified"] is True
    assert payload["completed_tasks"] == ["deliver-alpha", "deliver-beta"]
    assert payload["completion_audit"]["status"] == "achieved"
    calls = [json.loads(line) for line in worker_capture.read_text().splitlines()]
    assert [item["phase"] for item in calls if item["task_id"] == "deliver-alpha"] == [
        "build", "critic", "repair", "critic"
    ]
    assert [item["phase"] for item in calls if item["task_id"] == "deliver-beta"] == [
        "build", "critic"
    ]
    for task_id, tag in (("deliver-alpha", "v1.2.0"), ("deliver-beta", "v1.3.0")):
        done = read(prepared["repo"] / f".go/tasks/done/{task_id}.json")
        assert done["review_status"] == "approved"
        assert done["release_receipt"]["tag"] == tag
        release_commit = git(prepared["repo"], "rev-parse", tag + "^{commit}")
        assert git(
            prepared["repo"], "ls-remote", "origin", "refs/tags/" + tag + "^{}"
        ).startswith(release_commit)
    assert tree(root / ".go") == source_state
    print(json.dumps({
        "schema": "go-workflow.template-autonomy-proof.v1",
        "status": "passed",
        "runtime_ref": pin,
        "runtime_commit": runtime_commit,
        "source_state_unchanged": True,
        "missing_authority_refused_before_worker": True,
        "model_execution": "deterministic native CLI double; no model calls",
        "completed_tasks": payload["completed_tasks"],
        "goal_audit": payload["completion_audit"],
    }, indent=2))

print("TEMPLATE_AUTONOMY_ALL_PASSED")
PY
