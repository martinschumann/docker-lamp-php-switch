(
    set -euo pipefail

    if [[ -z "${MARIADB_ROOT_PASSWORD:-}" ]]; then
        log "MariaDB root password is missing" "ERROR"
        exit 1
    fi

    root_password_sql="$(docker_sql_escape_string_literal "$MARIADB_ROOT_PASSWORD")"

    log "Adding unix_socket authentication for root@localhost"
    docker_process_sql --binary-mode --skip-ssl <<SQL
SET SESSION sql_mode = REPLACE(@@SESSION.sql_mode, 'NO_BACKSLASH_ESCAPES', '');

ALTER USER 'root'@'localhost'
    IDENTIFIED VIA unix_socket
    OR mysql_native_password USING PASSWORD('${root_password_sql}');
SQL
)
