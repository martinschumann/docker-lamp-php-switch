#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

scripts=(
    "/docker/entrypoint.d/generate-root-ca-certificate.sh"
    "/docker/entrypoint.d/generate-server-certificate.sh"
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
