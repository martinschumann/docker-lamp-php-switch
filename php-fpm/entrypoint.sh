#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

scripts=(
    "/docker/entrypoint.d/forward-mariadb.sh"
    "/docker/entrypoint.d/install-composer.sh"
    "/docker/entrypoint.d/provision-user-environment.sh"
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
