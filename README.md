
# Go Project Template

Minimal template repo for projects that carry their own repo-local `.go/` agent contract.

Use this as a copy/start point for a new project. The `.go/` folder is intentionally the main artifact here.

## Contains

- `.go/project.json`
- `.go/architecture-principles.json`
- `.go/vision.json`
- `.go/hierarchy.json`
- `.go/tasks/open/task-schema-smoke.json`
- `.go/evidence/events.jsonl`

## Validate

From `../go-workflow-stack`:

```bash
python3 cli/go.py validate ../go-project-template
python3 cli/go.py readback ../go-project-template
```
