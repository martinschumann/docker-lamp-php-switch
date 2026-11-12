#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

readonly password_file="${MARIADB_ROOT_PASSWORD_FILE:?Set MARIADB_ROOT_PASSWORD_FILE}"

if [[ ! -d /var/lib/mysql/mysql && ! -e "$password_file" ]]; then
    (
        log "Generating random root password for MariaDB"
        umask 077
        tmp_file="$(mktemp "${password_file}.XXXXXX")"
        trap 'rm -f -- "$tmp_file"' EXIT

        pwgen --secure -1 32 > "$tmp_file"
        test -s "$tmp_file"
        ln -T -- "$tmp_file" "$password_file"
        log $(printf 'MariaDB root password saved to: %s\n' "$password_file")
    )
fi

if [[ ! -f "$password_file" || ! -r "$password_file" || -z "$(<"$password_file")" ]]; then
    log $(printf 'MariaDB root password file must be readable and non-empty: %s\n' "$password_file") "ERROR"
    exit 1
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"
