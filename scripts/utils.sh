#!/bin/bash

set -euo pipefail

log() {
    local timestamp
    local phase
    local level="${2:-INFO}"
    local script="${0}"
    local message="${1:-}"

    if [ -n "${BUILD_PHASE:-}" ]; then
        phase="BUILD"
    elif [ "$$" -eq 1 ]; then
        phase="ENTRYPOINT"
    else
        phase="RUNTIME"
    fi

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Replace linefeeds with a safe character sequence
    message="${message//$'\n'/\\n}"
    message="${message//$'\r'/\\r}"

    if [[ "$level" == "ERROR" || "$level" == "WARN" ]]; then
        printf "[%s] [%s] [%s] [%s] %s\n" "$timestamp" "$phase" "$level" "$script" "$message" >&2
    else
        printf "[%s] [%s] [%s] %s\n" "$timestamp" "$phase" "$level" "$message"
    fi
}

export -f log

assert_envs() {
    for env_name in "$@"; do
        if [[ -z "${!env_name+x}" ]]; then
            log "Environment variable $env_name not set." "ERROR"
            exit 1
        fi

        local -n current_var="$env_name"

        if [[ -z "$current_var" ]]; then
            log "Environment variable $env_name is empty." "WARN"
        fi
    done
}

export -f assert_envs

assert_files() {
    for file_path in "$@"; do
        if [[ -z "${file_path:-}" || ! -f "$file_path" ]]; then
            log "Required file is missing: ${file_path:-(empty path)}" "ERROR"
            exit 1
        fi
    done
}
export -f assert_files

get_key_checksum() {
    openssl pkey -pubout -in "$1" 2>/dev/null | openssl sha256 | awk '{print $NF}';
}
export -f get_key_checksum

get_csr_checksum() {
    openssl req -pubkey -noout -in "$1" 2>/dev/null | openssl sha256 | awk '{print $NF}';
}
export -f get_csr_checksum

get_cert_checksum() {
    openssl x509 -pubkey -noout -in "$1" 2>/dev/null | openssl sha256 | awk '{print $NF}';
}
export -f get_cert_checksum



