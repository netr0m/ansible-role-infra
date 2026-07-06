#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_failure SIGINT SIGTERM ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

NEW_SVC_NAME=""
FROM_SVC_NAME="actual"

DEFAULTS_DIR="$SCRIPT_DIR/defaults/main"
TASKS_DIR="$SCRIPT_DIR/tasks"
TEMPLATES_COMPOSE_DIR="$SCRIPT_DIR/templates/compose"
VARS_DIR="$SCRIPT_DIR/vars/main"

MAIN_DEFAULTS_FILEPATH="$DEFAULTS_DIR/main.yml"
MAIN_TASKS_FILEPATH="$TASKS_DIR/main.yml"

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-f <from_service_name>] -n <new_service_name>

Add a new service 'new_service_name', replacing all references to the 'from_service_name' with the new service's name.
    The service 'from_service_name' is used as the template for the new service.

-h, --help  Print this help and exit
-f, --from  The name of the service to use as the template. Defaults to '${FROM_SVC_NAME}' if absent.
-n, --name  The name of the new service to add


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
        -n | --name)
            NEW_SVC_NAME="${2-}"
            shift
            ;;
        -f | --from)
            FROM_SVC_NAME="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    [[ -z "${NEW_SVC_NAME-}" ]] && die "Missing required parameter '--name'"
    [[ -z "${FROM_SVC_NAME-}" ]] && die "Missing required parameter '--from'"

    return 0
}

parse_params "$@"

create_service_files() {
    # Defaults
    cp "$DEFAULTS_DIR/$FROM_SVC_NAME.yml" "$DEFAULTS_DIR/$NEW_SVC_NAME.yml"
    sed -i "s/$FROM_SVC_NAME/$NEW_SVC_NAME/Ig" "$DEFAULTS_DIR/$NEW_SVC_NAME.yml"

    # Tasks
    cp "$TASKS_DIR/deploy_$FROM_SVC_NAME.yml" "$TASKS_DIR/deploy_$NEW_SVC_NAME.yml"
    sed -i "s/$FROM_SVC_NAME/$NEW_SVC_NAME/Ig" "$TASKS_DIR/deploy_$NEW_SVC_NAME.yml"

    # Compose template
    cp "$TEMPLATES_COMPOSE_DIR/$FROM_SVC_NAME.yml.j2" "$TEMPLATES_COMPOSE_DIR/$NEW_SVC_NAME.yml.j2"
    sed -i "s/$FROM_SVC_NAME/$NEW_SVC_NAME/Ig" "$TEMPLATES_COMPOSE_DIR/$NEW_SVC_NAME.yml.j2"

    # Vars
    cp "$VARS_DIR/$FROM_SVC_NAME.yml" "$VARS_DIR/$NEW_SVC_NAME.yml"
    sed -i "s/$FROM_SVC_NAME/$NEW_SVC_NAME/Ig" "$VARS_DIR/$NEW_SVC_NAME.yml"
}

main() {
    create_service_files
    msg "Make sure to validate the new service files, replace the Docker image and version, and check the ports and volumes in the compose file."
    msg "Next steps:\n\t- $MAIN_DEFAULTS_FILEPATH: Ensure that you add 'infra_use_$NEW_SVC_NAME: false'\n\n\t- $MAIN_TASKS_FILEPATH: Ensure that you import the task 'deploy_$NEW_SVC_NAME.yml'\n\n\t- README.md: Ensure to add '$NEW_SVC_NAME' to the table of services"
}

main
