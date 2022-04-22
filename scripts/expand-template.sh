#!/bin/bash

set -Eeuo pipefail

# A script that sanitizes and normalizes path, and expand templates in a
# consistent way into the build dir.
# 
# Does the following steps
# - Normalizes path and takes relative paths respect to project root
# - Executes .env in the context dir
# - Executes .env.override in the context dir
# - Expand templates into the build dir

setup_vars() {
    PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    local inputs=()
    inputs=("${1:?input-dir required}")
    inputs+=("${2:-${PROJECT_DIR}/build}")
    inputs+=("${3:-${inputs[0]}/.env}")
    inputs+=("${4:-${inputs[0]}/.env.override}")
    
    # Sanitize paths to ensure nothing goes out of the project dir
    local i=0
    local path
    local rpath
    while [[ $i -lt "${#inputs[@]}" ]]; do
        # Find the canonical path
        path=$(readlink -m "${inputs[$i]}")
        # Resolve the path relative to project dir. This is important
        # since other gomplate will end up with a full path tree inside the build dir
        rpath=$(realpath --relative-to="${PROJECT_DIR}" "$path")
        verify_path_scopes "$rpath"
        # We normalize every path to project relative
        inputs[$i]="./$rpath"
        if [[ $i -lt 3 ]]; then i=$((i+1)); else break; fi
    done

    INPUT_DIR="${inputs[0]?invalid input dir}"
    OUTPUT_ROOT_DIR="${inputs[1]}"
    ENVFILE="${inputs[2]}"
    ENVFILE_OVERRIDE="${inputs[3]}"

    cd "$PROJECT_DIR"
}

verify_path_scopes() {
    # If the path is either the project dir, or outside of the project tree,
    # refuse to build. Requires a dir scoped env files for templating to work
    # If full build is needed, better just to run it over each of the dirs
    # with find, ignoring what's irrelevant

    local relative_path=${1?path required}
    if [[ "$relative_path" == "." ]]; then
        echo "Templating is dir scoped and cannot be run project wide" 
        exit 1
    elif [[ "$relative_path" == ../* ]]; then
        echo "Path outside of project scopes are not allowed." 
        exit 1
    fi
}

main() {
    if [[ "$#" -lt 1 ]]; then 
        usage; exit;
    fi
    setup_vars "$@"
    expand_template
}

check_prereq() {
    :
    # check for realpath from GNU coreutils is required. Please install coreutils. 
}

usage() {
    echo "Usage: $0 <input-dir> [output-root-dir] [envfile] [envfile-override]"
    echo ""
    echo "Note: input-dir is relative to the project root"
    echo "Defaults:"
    echo "  output-root-dir: <project>/build"
    echo "  envfile: <input-dir>/.env"
    echo "  envfile-override: <input-dir>/.env.override"
}

expand_template() {
    local input="${INPUT_DIR}"
    local output_root="${OUTPUT_ROOT_DIR}"
    local envfile="${ENVFILE}"
    local envfile_override="${ENVFILE_OVERRIDE}"

    local output="${output_root}/${input}"
    
    [[ -f "${envfile}" ]] && export $(xargs < "${envfile}")
    [[ -f "${envfile_override}" ]] && export $(xargs < "${envfile_override}")
    
    gomplate --input-dir "${input}" --output-dir "${output}"
}

main "$@"