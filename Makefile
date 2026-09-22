GO_STACK ?= ../go-workflow-stack
PYTHON ?= python3

.PHONY: check
check:
	$(PYTHON) "$(GO_STACK)"/cli/go.py validate .
	$(PYTHON) "$(GO_STACK)"/cli/go.py readback .
	$(PYTHON) "$(GO_STACK)"/cli/go.py pairing template --template "$(CURDIR)" --stack-repo "$(GO_STACK)" --json
	$(PYTHON) "$(GO_STACK)"/cli/go.py status . --json >/tmp/go-project-template-status.json
	cd "$(GO_STACK)" && stack_cli="$$PWD/cli/go.py" && cd / && $(PYTHON) "$$stack_cli" template-check "$(CURDIR)" --json >/tmp/go-project-template-pairing.json

.PHONY: check-abc
check-abc:
	bash scripts/test-abc-template.sh

.PHONY: check-guided
check-guided:
	bash scripts/test-guided-onboarding.sh

.PHONY: check-autonomy
check-autonomy:
	bash scripts/test-autonomy-onboarding.sh
