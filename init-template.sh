#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_failure SIGINT SIGTERM ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

TEMPLATE_AUTHOR_NAME="netr0m"
TEMPLATE_REPO_NAME="ansible-role-template"
TEMPLATE_ROLE_NAME="template"
TEMPLATE_FILES_WITH_REFS=(
    "meta/main.yml" "molecule/default/converge.yml"
    "LICENSE" "README.md" "example_playbook.yml"
    ".github/workflows/ci.yml" ".github/workflows/lint.yml"
    ".github/workflows/molecule.yml"
)

ROLE_AUTHOR=""
REPO_NAME=""
ROLE_NAME=""

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-r <repository_name>] -a <author> -n <role_name>

Initialize the template, replacing all references to this role's author with the specified author,
and the references to this role's name with the specified role name.

-h, --help      Print this help and exit
-r, --repo      The name of the repository. Defaults to the value of '--name' if absent.
-a, --author    The username of the author of the new role (you?)
-n, --name      The name of the new role


EOF
    exit
}

cleanup_failure() {
    trap - SIGINT SIGTERM ERR
    failed_at=$(date +%d-%m-%Y-%H:%M:%S)
    git stash save "failed/${failed_at}"
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1}
    msg "$msg"
    exit "$code"
}

parse_params() {
    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -a | --author)
            ROLE_AUTHOR="${2-}"
            shift
            ;;
        -n | --name)
            ROLE_NAME="${2-}"
            shift
            ;;
        -r | --repo)
            REPO_NAME="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    [[ -z "${ROLE_AUTHOR-}" ]] && die "Missing required parameter '--author'"
    [[ -z "${ROLE_NAME-}" ]] && die "Missing required parameter '--name'"
    [[ -z "${REPO_NAME-}" ]] && REPO_NAME="$ROLE_NAME"

    return 0
}

parse_params "$@"

set_upstream() {
    git remote rename origin upstream
}

replace_refs() {
    for filepath in "${TEMPLATE_FILES_WITH_REFS[@]}"; do
        msg "Replacing references in $filepath.."
        sed -i "s/$TEMPLATE_AUTHOR_NAME/$ROLE_AUTHOR/g" "$SCRIPT_DIR/$filepath"
        sed -i "s/$TEMPLATE_REPO_NAME/$REPO_NAME/g" "$SCRIPT_DIR/$filepath"
        sed -i "s/$TEMPLATE_ROLE_NAME/$ROLE_NAME/g" "$SCRIPT_DIR/$filepath"
    done
    msg "Replacing title in README.md"
    sed -i "s/$TEMPLATE_ROLE_NAME/$ROLE_NAME/ig" "$SCRIPT_DIR/README.md"
}

main() {
    set_upstream
    replace_refs
    msg "Make sure to add the git remote, e.g.:\n\tgit remote add origin git@github.com:$ROLE_AUTHOR/$REPO_NAME.git"
}

main
