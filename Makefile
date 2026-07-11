GO_STACK ?= ../go-workflow-stack

.PHONY: check
check:
	python3 $(GO_STACK)/cli/go.py validate .
	python3 $(GO_STACK)/cli/go.py readback .
	python3 $(GO_STACK)/cli/go.py status . --json >/tmp/go-project-template-status.json
	python3 $(GO_STACK)/cli/go.py template-check . --json >/tmp/go-project-template-pairing.json
