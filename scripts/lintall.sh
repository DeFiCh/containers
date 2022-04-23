#!/bin/bash

set -Eeuo pipefail

main() {
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "${PROJECT_DIR}"
    docker run -e LOG_LEVEL=WARN -e RUN_LOCAL=true -v "${PROJECT_DIR}":/tmp/lint docker.io/github/super-linter
}

main "$@"