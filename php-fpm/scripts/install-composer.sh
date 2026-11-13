#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

log "Running $(hostname):$(realpath "${BASH_SOURCE[0]}")"

installer="$(mktemp)"
trap 'rm -f -- "$installer"' EXIT

if ! checksum="$(php -r 'exit(copy("https://composer.github.io/installer.sig", "php://stdout") ? 0 : 1);')"; then
    log "Failed to download the Composer installer checksum" "ERROR"
    exit 1
fi

if ! php -r 'exit(copy("https://getcomposer.org/installer", $argv[1]) ? 0 : 1);' "$installer"; then
    log "Failed to download the Composer installer" "ERROR"
    exit 1
fi

if [[ "$checksum" != "$(sha384sum -- "$installer" | cut -d ' ' -f 1)" ]]; then
    log "Could not verify the Composer installer checksum" "ERROR"
    exit 1
fi

php "$installer" --quiet --install-dir=/usr/local/bin --filename=composer
/usr/local/bin/composer --version --no-ansi
