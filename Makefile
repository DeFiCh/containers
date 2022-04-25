SHELL := /bin/bash

SELF_PATH_BASE := $(lastword $(MAKEFILE_LIST))
SELF_PATH := $(abspath $(SELF_PATH_BASE))
PROJECT_DIR := $(patsubst %/$(SELF_PATH_BASE),%,$(SELF_PATH))

BUILD_DIR ?= build
BUILD_DIR := $(patsubst %/, %, $(BUILD_DIR))

# Certain target only requirements
CONTEXT_DIR ?=
ENV_FILE ?=
ENV_OVERRIDE_FILE ?=
DOCKERFILE ?= 
TAG ?= 


# If the bin is present in env, it's used, otherwise, it's installed into
# workspace path, and then used.
GOMPLATE_BIN ?= gomplate
WORKSPACE_GOMPLATE_BIN := $(BUILD_DIR)/bin/gomplate

ALL_TEMPLATE_CONTEXTS := $(filter-out $(BUILD_DIR)/, $(wildcard */))
GIT_HOOK := $(PROJECT_DIR)/.git/hooks/pre-push

.ONESHELL:

.PHONY: default
default: check

.PHONY: check
check: add-githook lint expand-templates-all 

.PHONY: clean
clean:
	rm -rf "$(BUILD_DIR)" super-linter.log

.PHONY: lint
lint:
	@docker run -e LOG_LEVEL=WARN -e RUN_LOCAL=true \
		-v "$(PROJECT_DIR)":/tmp/lint docker.io/github/super-linter

.PHONY: shellcheck
shellcheck:
	@find . -type f -name "*.sh" -exec shellcheck {} \;

.PHONY: add-githook
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

	[[ "$(WORKSPACE_GOMPLATE_BIN)" != "$(GOMPLATE_BIN)" ]] && exit 0
	mkdir -p "$$(dirname "$(WORKSPACE_GOMPLATE_BIN)")"
	container_hash="$$(docker create docker.io/hairyhenderson/gomplate:stable)"
	docker cp "$$container_hash":/gomplate "$(WORKSPACE_GOMPLATE_BIN)"
	docker rm "$$container_hash"

.PHONY: expand-templates
expand-templates: ensure-pkg-gomplate
	@if [[ -z "$(CONTEXT_DIR)" ]]; then
		echo "CONTEXT_DIR arg is required"
		exit 1
	fi
	context_dir="$(CONTEXT_DIR)"
	build_dir="$(BUILD_DIR)"
	env_file="$(ENV_FILE)"
	env_override_file="$(ENV_OVERRIDE_FILE)"
	gomplate_bin="$(GOMPLATE_BIN)"

	env_file="$${env_file:-$${context_dir}/.env}"
	env_override_file="$${env_override_file:-$${context_dir}/.env.override}"
	set -o allexport;
	[[ -f "$$env_file" ]] && source "$$env_file"
	[[ -f "$$env_override_file" ]] && source "$$env_override_file"
	set +o allexport;

	output_dir="$$build_dir/$$context_dir"
	"$$gomplate_bin" --input-dir "$$context_dir" --output-dir "$$output_dir"

.PHONY: expand-templates-all
expand-templates-all: ensure-pkg-gomplate
	@for ctx in $(ALL_TEMPLATE_CONTEXTS); do
		echo "Expand: $$ctx"
		$(MAKE) expand-templates CONTEXT_DIR="$$ctx"
	done

.PHONY: docker-build
docker-build: 
	@tag="$(TAG)"
	dockerfile="$(DOCKERFILE)"
	suffix=".local-build"
	context_dir="$(CONTEXT_DIR)"

	if [[ -z "$(DOCKERFILE)" ]]; then
		echo "DOCKERFILE arg is required"
		exit 1
	fi

	if [[ -z "$$context_dir" ]]; then
		if [[ -z "$$tag" ]]; then
		  tag="$$(basename "$$dockerfile")$$suffix"
		  tag="$${tag,,}"
		fi
		echo "build no-context: $$dockerfile => $$tag"
		docker build -t "$$tag" - < "$$dockerfile"
	else 
		if [[ -z "$$tag" ]]; then
		  tag="$$(basename "$$context_dir")-$$(basename "$$dockerfile")$$suffix"
		  tag="$${tag,,}"
		fi
		echo "build with context: $$dockerfile => $$tag"
		docker build -f "$$dockerfile" -t "$$tag" "$$context_dir"
	fi

.PHONY: build
build: 
	@if [[ -z "$(CONTEXT_DIR)" ]]; then
		$(MAKE) docker-build BUILD_DIR="$(BUILD_DIR)" \
			TAG="$(TAG)" DOCKERFILE="$(DOCKERFILE)"
		exit
	fi
	
	echo "expand-templates: $(CONTEXT_DIR)"
	$(MAKE) expand-templates BUILD_DIR="$(BUILD_DIR)" \
		CONTEXT_DIR="$(CONTEXT_DIR)";

	$(MAKE) docker-build BUILD_DIR="$(BUILD_DIR)" \
		TAG="$(TAG)" CONTEXT_DIR="$(BUILD_DIR)/$(CONTEXT_DIR)" \
		DOCKERFILE="$(BUILD_DIR)/$(DOCKERFILE)"
