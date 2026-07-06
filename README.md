# Go Project Template

![Go Project Template hero](assets/hero.svg)

A minimal starter repository for projects that carry their own repo-local `.go/` agent workflow state.

Use this repo as the copyable template when starting a new project that should be understandable by agents from the repository alone. It pairs with [`go-workflow-stack`](https://github.com/viggomeesters/go-workflow-stack), which provides the CLI, schemas, validators, and reusable workflow rules.

## Practical architecture in one minute

This repo is the starter structure. The stack repo is the toolbelt. Your real project repo owns its own `.go/` state.

```text
go-workflow-stack  -> validates/operates -> project repo with .go/
go-project-template -> seeds/copies ------^
```

For the full architecture and practical application flow, see [`docs/practical-architecture.md`](docs/practical-architecture.md).

## What this gives you

```text
.go/
  project.json
  architecture-principles.json
  vision.json
  hierarchy.json
  tasks/open/task-schema-smoke.json
  evidence/events.jsonl
```

## Installation

Use GitHub's template/copy flow or clone the repository directly. Keep the `.go/` folder tracked when adapting it for a real project.

## Usage

Clone this template next to the workflow stack:

```bash
git clone https://github.com/viggomeesters/go-workflow-stack.git
git clone https://github.com/viggomeesters/go-project-template.git
cd go-project-template
make check
```

Or validate directly from the stack repo:

```bash
cd ../go-workflow-stack
python3 cli/go.py validate ../go-project-template
python3 cli/go.py readback ../go-project-template
```

## Customize for a real project

Edit the `.go/` files:

- `.go/project.json`: project id, name, default verification.
- `.go/architecture-principles.json`: project constraints and enforcement rules.
- `.go/vision.json`: north star, wedge, target user, promise, non-goals.
- `.go/hierarchy.json`: epic-lite work packages, features, and task links.
- `.go/tasks/open/*.json`: first executable tasks.

## Development

Use local validation before committing or publishing changes. The check compiles the Python CLI where applicable and validates the template repository contract.

```bash
make check
bash scripts/check.sh
```

## Privacy and security

The included `.go/` state is synthetic. Do not use private vault data, credentials, customer material, or local runtime artifacts in a public template.

## License

This project is released under the MIT License. See [`LICENSE`](LICENSE) for the full license text.
