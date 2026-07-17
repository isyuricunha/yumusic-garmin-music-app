# YuMusic — Connect IQ build / test / install helpers.
# Run `make` (or `make help`) for the target list.
# Override any variable on the command line, e.g. `make build DEVICE=fr965`.

# Latest installed Connect IQ SDK (override with SDK=/path/to/sdk).
SDK    ?= $(shell ls -d "$(HOME)/Library/Application Support/Garmin/ConnectIQ/Sdks/"*/ 2>/dev/null | sort | tail -1)
DEVICE ?= fr165m
KEY    ?= $(abspath ../developer_key)
NAME   ?= yumusic
JUNGLE ?= monkey.jungle

MONKEYC  = "$(SDK)/bin/monkeyc"
MONKEYDO = "$(SDK)/bin/monkeydo"
SIM      = "$(SDK)/bin/connectiq"

OUT      = /tmp/$(NAME).prg
TEST_OUT = /tmp/$(NAME)-test.prg
IQ_OUT   = $(NAME).iq

# macOS mounts a USB-connected watch under /Volumes/GARMIN.
DEST ?= /Volumes/GARMIN/GARMIN/APPS

.DEFAULT_GOAL := help
.PHONY: help check build run sim test package install clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-9s\033[0m %s\n",$$1,$$2}'

check: ## Print the resolved SDK / device / key
	@echo "SDK    = $(SDK)"
	@echo "DEVICE = $(DEVICE)"
	@echo "KEY    = $(KEY)"
	@test -x $(MONKEYC) && echo "monkeyc: OK" || echo "monkeyc: NOT FOUND"
	@test -f $(KEY) && echo "key: OK" || echo "key: NOT FOUND"

build: ## Compile a signed .prg for DEVICE -> $(OUT)
	$(MONKEYC) -f $(JUNGLE) -d $(DEVICE) -o $(OUT) -y $(KEY)

run: build ## Build then launch it in the simulator
	$(MONKEYDO) $(OUT) $(DEVICE)

sim: ## Launch the Connect IQ simulator (background)
	$(SIM) &

test: ## Build unit tests and run them in the simulator
	$(MONKEYC) -f $(JUNGLE) -d $(DEVICE) -o $(TEST_OUT) -y $(KEY) --unit-test
	$(MONKEYDO) $(TEST_OUT) $(DEVICE) -t

package: ## Build an exportable .iq store package (all products in the manifest)
	$(MONKEYC) -e -f $(JUNGLE) -o $(IQ_OUT) -y $(KEY)

install: build ## Build then copy the .prg to a USB-connected watch ($(DEST))
	@test -d "$(DEST)" || { echo "Watch not mounted at $(DEST). Connect it via USB."; exit 1; }
	cp $(OUT) "$(DEST)/$(NAME).prg"
	@echo "Installed to $(DEST)/$(NAME).prg — eject the watch, then launch YuMusic."

clean: ## Remove build artifacts
	rm -f $(OUT) $(TEST_OUT) $(IQ_OUT)
