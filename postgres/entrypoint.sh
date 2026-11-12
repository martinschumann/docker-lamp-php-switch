#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

readonly password_file="${POSTGRES_PASSWORD_FILE:?Set POSTGRES_PASSWORD_FILE}"

if [[ ! -s "$PGDATA/PG_VERSION" && ! -e "$password_file" ]]; then
    (
        log "Generating random password for PostgreSQL"
        umask 077
        tmp_file="$(mktemp "${password_file}.XXXXXX")"
        trap 'rm -f -- "$tmp_file"' EXIT

        pwgen --secure -1 32 > "$tmp_file"
        test -s "$tmp_file"
        ln -T -- "$tmp_file" "$password_file"
        log "PostgreSQL password saved to: $password_file"
    )
fi

if [[ ! -f "$password_file" || ! -r "$password_file" || -z "$(<"$password_file")" ]]; then
    log "PostgreSQL password file must be readable and non-empty: $password_file" "ERROR"
    exit 1
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
