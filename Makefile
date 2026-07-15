GO_STACK ?= ../go-workflow-stack
PYTHON ?= python3

.PHONY: check
check:
	$(PYTHON) $(GO_STACK)/cli/go.py validate .
	$(PYTHON) $(GO_STACK)/cli/go.py readback .
	$(PYTHON) $(GO_STACK)/cli/go.py status . --json >/tmp/go-project-template-status.json
	$(PYTHON) $(GO_STACK)/cli/go.py template-check . --json >/tmp/go-project-template-pairing.json
