#!/bin/bash

set -euo pipefail

log() {
    local timestamp
    local level="${2:-INFO}"
    local script="${0}"
    local message="${1:-}"

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Replace linefeeds with a safe character sequence
    message="${message//$'\n'/\\n}"
    message="${message//$'\r'/\\r}"

    if [[ "$level" == "ERROR" || "$level" == "WARN" ]]; then
        printf "[%s] [%s] [%s] [%s] %s\n" "$timestamp" "$level" "$script" "$message" >&2
    else
        printf "[%s] [%s] [%s] %s\n" "$timestamp" "$level" "$message"
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
    if [ $# -eq 0 ]; then
        return 1
    fi

    openssl pkey -pubout -in "$1" 2>/dev/null | openssl sha256 | awk '{print $NF}' | tr -d '\r\n';
}
export -f get_key_checksum

get_csr_checksum() {
    if [ $# -eq 0 ]; then
        return 1
    fi

    openssl req -pubkey -noout -in "$1" 2>/dev/null | openssl sha256 | awk '{print $NF}' | tr -d '\r\n';
}
export -f get_csr_checksum

get_cert_checksum() {
    if [ $# -eq 0 ]; then
        return 1
    fi

    openssl x509 -pubkey -noout -in "$1" 2>/dev/null | openssl sha256 | awk '{print $NF}' | tr -d '\r\n';
}
export -f get_cert_checksum
