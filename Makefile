SHELL := /bin/bash
BUILD_DIR := build

# If the bin is present in env, it's used, otherwise, it's installed into
# workspace path, and then used.
GOMPLATE_BIN := gomplate
WORKSPACE_GOMPLATE_BIN := $(BUILD_DIR)/bin/gomplate

GIT_HOOK := .git/hooks/pre-commit

.ONESHELL:

.PHONY: default
default: check

.PHONY: check
check: add-githook lint expand-templates-all 

.PHONY: clean
clean:
	rm -rf "$(BUILD_DIR)"

.PHONY: lint
lint:
	@docker run -e LOG_LEVEL=WARN -e RUN_LOCAL=true \
		-v "$(CURDIR)":/tmp/lint docker.io/github/super-linter

.PHONY: shellcheck
shellcheck:
	@find . -type f -name "*.sh" -exec shellcheck {} \;

.PHONY: githook-add
add-githook:
	@mkdir -p "$$(dirname $(GIT_HOOK))"
	tee "$(GIT_HOOK)" <<END
	#!/bin/bash
	make check
	END
	chmod +x "$(GIT_HOOK)"

.PHONY: remove-githook
remove-githook:
	rm "$(GIT_HOOK)"

# This first checks if GOMPLATE_BIN is available. If it is, doesn't do
# anything. If it isn't, uses the stable docker image to pull the binary
# and place it into the workspace dir to be used, and resets the 
# GOMPLATE_BIN so that the workspace path is for invocation. 
.PHONY: ensure-pkg-gomplate
ensure-pkg-gomplate:
	@$(eval GOMPLATE_BIN := $(shell \
	if [[ ! $$(command -v $(GOMPLATE_BIN)) ]]; \
	then echo "$(WORKSPACE_GOMPLATE_BIN)"; \
	else echo "$(GOMPLATE_BIN)"; fi))

	[[ "$$(command -v $(GOMPLATE_BIN))" ]] && exit 0
	mkdir -p "$$(dirname "$(WORKSPACE_GOMPLATE_BIN)")"
	container_hash="$$(docker create docker.io/hairyhenderson/gomplate:stable)"
	docker cp "$${container_hash}":/gomplate "$(WORKSPACE_GOMPLATE_BIN)"
	docker rm "$${container_hash}"

.PHONY: expand-templates
expand-templates: ensure-pkg-gomplate
	@if [[ -z "$(CONTEXT_DIR)" ]]; then
		echo "CONTEXT_DIR arg is required"
		exit 1
	fi
	GOMPLATE_BIN="$(GOMPLATE_BIN)" ./scripts/expandtemplates.sh "$(CONTEXT_DIR)" "$(BUILD_DIR)"

.PHONY: expand-templates-all
expand-templates-all: ensure-pkg-gomplate
	@find . -mindepth 1 -type d \
		\( -path "./.github" -o -path "./scripts" -o -path "./.git" -o \
		 -path "./$(BUILD_DIR)" \) -prune \
		-o -type d -exec env GOMPLATE_BIN="$(GOMPLATE_BIN)" \
		./scripts/expandtemplates.sh {} "$(BUILD_DIR)" \;
