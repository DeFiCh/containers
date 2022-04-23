#!/bin/bash

set -Eeuo pipefail

setup_vars() {
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    GIT_HOOK=".git/hooks/pre-commit"
}

main() {
    [[ "$#" -eq 0 ]] && { usage; exit; } 
    setup_vars
    cd "${PROJECT_DIR}"
    if [[ "${1:-}" == "0" ]]; then
        remove_hook
    else
        add_hook
    fi
}

usage() {
    echo "Usage: $0 [1|0]"
    echo ""
    echo "1 = add hooks"
    echo "0 = remove hooks"
}

add_hook() {
    mkdir -p "$(dirname $GIT_HOOK)"
    tee "$GIT_HOOK" <<END
#!/bin/bash
make check
END
    chmod +x "$GIT_HOOK"
}

remove_hook() { 
    rm "$GIT_HOOK"
}

main "$@"

