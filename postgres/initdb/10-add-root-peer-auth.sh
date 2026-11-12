#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

log "Enable PostgreSQL peer authentication for OS user root as database role postgres"

printf '\n%s\n' \
    'postgres_admin   root       postgres' \
    'postgres_admin   postgres   postgres' \
    >> "$PGDATA/pg_ident.conf"

sed -i '1i local   all   postgres   peer map=postgres_admin' \
    "$PGDATA/pg_hba.conf"