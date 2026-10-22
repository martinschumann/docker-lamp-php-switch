#!/usr/bin/env bash
set -euo pipefail

source /opt/pki/bin/utils.sh

scripts=(
    "/opt/pki/bin/export-certs.sh"
    "/opt/pki/bin/configure-apache.sh"
)

for script in "${scripts[@]}"; do
    [ -x "$script" ] || continue

    source "$script"

    if [ $? -ne 0 ]; then
        log "Booting entrypoint scripts aborted." "ERROR"
        exit 1
    fi
done

exec "$@"
