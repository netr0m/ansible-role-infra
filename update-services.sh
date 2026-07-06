#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup_failure SIGINT SIGTERM ERR

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

DEFAULTS_DIR="$SCRIPT_DIR/defaults/main"
NON_SERVICE_FILES=("main.yml")

SERVICES_TO_UPDATE=()
SERVICES_TO_SKIP=(graylog)
SUBSERVICES_TO_SKIP=(authentik_db unifi_db)

NON_INTERACTIVE=false

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-u <service_name> [-u <service_name>]] [-s <service_name> [-s <service_name>]]

Update services to the latest stable version, optionally limited to the service(s) specified by -u or excluding those specified by -s.

-h, --help      Print this help and exit
-u, --update    The name of the service to update (can be specified multiple times)
-s, --skip      The name of the service to skip (can be specified multiple times)
--no-skip       Do not skip any services or subservices (overrides -s)
-ni, --non-interactive  Run in non-interactive mode (do not prompt for user input).
                            Version will update to the digest of the latest tag.

EOF
    exit
}

cleanup_failure() {
    trap - SIGINT SIGTERM ERR
    echo "An unexpected error occurred"
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
        -u | --update)
            SERVICES_TO_UPDATE+=("${2-}")
            shift
            ;;
        -s | --skip)
            SERVICES_TO_SKIP+=("${2-}")
            shift
            ;;
        --no-skip)
            SERVICES_TO_SKIP=()
            SUBSERVICES_TO_SKIP=()
            ;;
        -ni | --non-interactive)
            NON_INTERACTIVE=true
            msg "Running in non-interactive mode."
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    return 0
}

parse_params "$@"

find_service_names() {
    local service_names=()
    for file in "$DEFAULTS_DIR"/*.yml; do
        local filename=$(basename "$file")
        if [[ " ${NON_SERVICE_FILES[*]} " == *" $filename "* ]]; then
            continue
        fi
        local service_name="${filename%.yml}"
        service_names+=("$service_name")
    done
    echo "${service_names[@]}"
}

get_service_var_name() {
    local service_name="$1"
    echo "${service_name//-/_}"
}

get_service_version_lines() {
    local service_name="$1"
    service_var_name=$(get_service_var_name "$service_name")

    mapfile -t version_lines < <(
        grep -E "[a-zA-Z]{1,20}_${service_var_name}_([a-zA-Z0-9]{1,10}_)?version:" "$DEFAULTS_DIR/$service_name.yml" || :
    )
}

get_service_git_tag_lines() {
    local service_name="$1"
    service_var_name=$(get_service_var_name "$service_name")

    mapfile -t git_tag_lines < <(
        grep -E "[a-zA-Z]{1,20}_${service_var_name}_([a-zA-Z0-9]{1,10}_)?git_tag:" "$DEFAULTS_DIR/$service_name.yml" || :
    )
}

get_service_container_images() {
    local service_name="$1"
    local -n _map="$2"

    service_var_name=$(get_service_var_name "$service_name")

    _map=()
    while IFS= read -r line; do
        key=$([[ "$line" =~ ^[^_]+_([^:]+)_container_image: ]] && echo "${BASH_REMATCH[1]}")
        _map["$key"]="$line"
    done < <(
        grep -E "[a-zA-Z]{1,20}_${service_var_name}_([a-zA-Z0-9]{1,10}_)?container_image:" "$DEFAULTS_DIR/$service_name.yml" || :
    )
}

get_service_git_repos() {
    local service_name="$1"
    local -n _map="$2"

    service_var_name=$(get_service_var_name "$service_name")

    _map=()
    while IFS= read -r line; do
        key=$([[ "$line" =~ ^[^_]+_([^:]+)_git_repository: ]] && echo "${BASH_REMATCH[1]}")
        _map["$key"]="$line"
    done < <(
        grep -E "[a-zA-Z]{1,20}_${service_var_name}_([a-zA-Z0-9]{1,10}_)?git_repository:" "$DEFAULTS_DIR/$service_name.yml" || :
    )
}

find_container_image_var() {
    local service_name="$1"

    service_var_name=$(get_service_var_name "$service_name")

    mapfile -t matches < <(
        grep -E "[a-zA-Z]{1,20}_${service_var_name}_([a-zA-Z0-9]{1,10}_)?container_image:" "$DEFAULTS_DIR/$service_name.yml" || :
    )
    if ((${#matches[@]} == 0)); then
        return 1
    else
        echo "${matches[0]}"
    fi
}

get_current_service_version() {
    local service_version_line="$1"
    current_version=$(echo "$service_version_line" | awk '{ print $2 }')
    echo "${current_version//\"/}"
}

get_service_container_image_repo() {
    local service_image_line="$1"
    repo_with_tag=$(echo "$service_image_line" | awk '{ print $2 }')
    repo_no_tag=$(echo "$repo_with_tag" | awk -F'[:@]' '{ print $1 }')
    echo "${repo_no_tag//\"/}"
}

get_service_git_repo() {
    local service_git_repo_line="$1"
    repo=$(echo "$service_git_repo_line" | awk '{ print $2 }')
    echo "${repo//\"/}"
}

get_latest_digest() {
    local service_image_repo="$1"
    if latest_digest=$(crane digest "$service_image_repo:latest"); then
        echo "$latest_digest"
        return 0
    else
        return 1
    fi
}

prompt_for_new_tag() {
    local service_repo="$1"
    msg "\tOpening the page for '$service_repo' in your default browser..."
    case "$service_repo" in
        docker.io/*)
            url="https://hub.docker.com/r/${service_repo#docker.io/}/tags"
            ;;
        ghcr.io/*)
            url="https://$service_repo"
            ;;
        https://* | http://*)
            url="$service_repo"
            ;;
        *)
            url="https://$service_repo"
            ;;
    esac
    xdg-open "$url" >/dev/null 2>&1 &
    read -r -p "        Enter the new tag: " new_tag

    if [[ -z $new_tag ]]; then
        return 1
    else
        echo "$new_tag"
        return 0
    fi
}

replace_version_line() {
    local service_name="$1"
    local old_version_line="$2"
    local new_version_line="$3"

    sed -i "s|$old_version_line|$new_version_line|g" "$DEFAULTS_DIR/$service_name.yml"
}

set_untagged_digest_container_image_line() {
    local service_name="$1"
    local current_container_image_line="$2"

    local container_image_line_value="${current_container_image_line#*: }"

    local container_image_line_value_with_digest_prefix="${container_image_line_value//:/@}"

    sed -i "s|$container_image_line_value|$container_image_line_value_with_digest_prefix|g" "$DEFAULTS_DIR/$service_name.yml"
}

set_tagged_container_image_line() {
    local service_name="$1"
    local current_container_image_line="$2"

    local container_image_line_with_tag_prefix="${current_container_image_line//@/:}"

    sed -i "s|$current_container_image_line|$container_image_line_with_tag_prefix|g" "$DEFAULTS_DIR/$service_name.yml"
}

non_interactive_update() {
    local kind="$1"
    local service_name="$2"
    local image_repo="$3"
    local current_version_line="$4"
    local current_container_image_line="$5"

    case "$kind" in
        container)
            if latest_digest=$(get_latest_digest "$image_repo"); then
                msg "\tLatest digest for $service_name is '$latest_digest'"
                set_untagged_digest_container_image_line "$service_name" "$current_container_image_line"
                new_version_line="${current_version_line%%:*}: \"$latest_digest\""
                replace_version_line "$service_name" "$current_version_line" "$new_version_line"
                msg "\tUpdated $service_name to digest '$latest_digest'"
            else
                msg "\tFailed to get latest digest for '$service_name'"
            fi
            ;;
        *)
            msg "\tNon-interactive update is only supported for container images. Skipping $service_name."
            ;;
    esac
}

prompt_based_update() {
    local kind="$1"
    local service_name="$2"
    local image_repo="$3"
    local current_version_line="$4"
    local current_container_image_line="$5"

    if new_tag=$(prompt_for_new_tag "$image_repo"); then
        msg "\tUpdating $service_name to tag '$new_tag'"
        case "$kind" in
            container)
                set_tagged_container_image_line "$service_name" "$current_container_image_line"
                ;;
            git)
                ;;
            *)
                msg "\tPrompt-based update is only supported for container images and git tags. Skipping $service_name."
                return 0
                ;;
        esac
        new_version_line="${current_version_line%%:*}: \"$new_tag\""
        replace_version_line "$service_name" "$current_version_line" "$new_version_line"
        msg "\tUpdated $service_name to version '$new_tag'"
    else
        msg "\tNo new tag provided for '$service_name'. Skipping update."
    fi
}

main() {
    services=$(find_service_names)
    for service_name in $services; do
        if [[ ${#SERVICES_TO_UPDATE[@]} -gt 0 && ! " ${SERVICES_TO_UPDATE[*]} " =~ " ${service_name} " ]]; then
            # msg "Skipping $service_name (not in update list)"
            continue
        fi

        # shellcheck disable=SC2076
        if [[ " ${SERVICES_TO_SKIP[*]} " =~ " ${service_name} " ]]; then
            msg "Skipping $service_name (in skip list)"
            continue
        fi

        msg "Processing service: $service_name"
        get_service_version_lines "$service_name"
        get_service_git_tag_lines "$service_name"

        declare -A image_map
        get_service_container_images "$service_name" image_map
        declare -A git_repo_map
        get_service_git_repos "$service_name" git_repo_map

        # container image based
        for version_var in "${version_lines[@]}"; do
            [[ "$version_var" =~ ^[^_]+_([^:]+)_version: ]] && subservice="${BASH_REMATCH[1]}"

            # shellcheck disable=SC2076
            if [[ " ${SUBSERVICES_TO_SKIP[*]} " =~ " ${subservice} " ]]; then
                msg "\tSkipping $subservice (in skip list)"
                continue
            fi

            current_version=$(get_current_service_version "$version_var")
            msg "\tService '$subservice' is currently @ $current_version"
            subservice_image_repo_var="${image_map[$subservice]:-}"
            if [ -z "$subservice_image_repo_var" ]; then
                if ! subservice_image_repo_var=$(find_container_image_var "$subservice"); then
                    msg "\tUnable to find '_container_image' variable for '$subservice'. Skipping."
                    continue
                fi
            fi
            image_repo=$(get_service_container_image_repo "$subservice_image_repo_var")
            case "$NON_INTERACTIVE" in
                true)
                    non_interactive_update "container" "$service_name" "$image_repo" "$version_var" "$subservice_image_repo_var"
                    ;;
                false)
                    prompt_based_update "container" "$service_name" "$image_repo" "$version_var" "$subservice_image_repo_var"
                    ;;
            esac
        done

        # git repo based
        for tag_var in "${git_tag_lines[@]}"; do
            [[ "$tag_var" =~ ^[^_]+_([^:]+)_(git_tag|version): ]] && subservice="${BASH_REMATCH[1]}"

            # shellcheck disable=SC2076
            if [[ " ${SUBSERVICES_TO_SKIP[*]} " =~ " ${subservice} " ]]; then
                msg "\tSkipping $subservice (in skip list)"
                continue
            fi

            current_tag=$(get_current_service_version "$tag_var")
            msg "\tService '$subservice' is currently @ $current_tag"
            subservice_git_repo_var="${git_repo_map[$subservice]}"
            git_repo=$(get_service_git_repo "$subservice_git_repo_var")
            case "$NON_INTERACTIVE" in
                true)
                    non_interactive_update "git" "$service_name" "$git_repo" "$tag_var" "$subservice_git_repo_var"
                    ;;
                false)
                    prompt_based_update "git" "$service_name" "$git_repo" "$tag_var" "$subservice_git_repo_var"
                    ;;
            esac
        done
    done

}

main
