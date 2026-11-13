#!/usr/bin/env bash
set -euo pipefail

source ./lib/utils.sh

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."

wait_for_tcp() {
    local service="$1"
    local password_file="$2"
    local query="$3"
    local result attempt

    for ((attempt = 1; attempt <= 20; attempt++)); do
        if test -s "$password_file" &&
           result=$(cat -- "$password_file" |
               docker compose exec -T --user ubuntu php-fpm sh -eu -c "$query") &&
           [[ "$result" == 1 ]]; then
            log "$service: TCP password authentication OK"
            return 0
        fi

        sleep 1
    done

    log "$service: TCP authentication with generated password failed" "ERROR" >&2
    docker compose logs --tail=50 "$service" >&2
    return 1
}

wait_for_tcp mariadb credentials/mariadb_root_pwd '
    password=$(cat)
    MYSQL_PWD="$password" mariadb --no-defaults --skip-ssl \
        --protocol=TCP -h mariadb -u root --connect-timeout=2 \
        --batch --skip-column-names -e "SELECT 1"
'

wait_for_tcp postgres credentials/postgres_root_pwd '
    password=$(cat)
    PGPASSWORD="$password" PGPASSFILE=/dev/null PGCONNECT_TIMEOUT=2 \
        psql -X -w -h postgres -U postgres -d postgres -Atc "SELECT 1"
'

if ! result=$(docker compose exec -T --user root php-fpm \
    env -u MYSQL_PWD mariadb --no-defaults \
    --protocol=SOCKET --socket=/run/mysqld/mysqld.sock \
    -u root --batch --skip-column-names -e 'SELECT 1') ||
   [[ "$result" != 1 ]]; then
    log "MariaDB: Unix socket peer authentication failed" "ERROR" >&2
    exit 1
fi

log "MariaDB: Unix socket peer authentication was successful"

if ! result=$(docker compose exec -T --user root php-fpm \
    env -u PGPASSWORD PGPASSFILE=/nonexistent/pgpass \
    psql -X -w -h /var/run/postgresql -U postgres -d postgres \
    -Atc 'SELECT 1') ||
   [[ "$result" != 1 ]]; then
    log "PostgreSQL: Unix socket peer authentication failed" "ERROR" >&2
    exit 1
fi

log "PostgreSQL: Unix socket peer authentication was successful"
