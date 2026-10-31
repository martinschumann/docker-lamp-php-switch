#!/usr/bin/env bash
set -euo pipefail

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [[ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]]; then
    rm composer-setup.php
    log "Invalid installer checksum" "ERROR"
fi

php composer-setup.php --quiet --install-dir=/usr/local/bin/ --filename=composer
RESULT=$?
rm composer-setup.php

if [[ "$RESULT" -gt 0 ]] || [[ ! -f /usr/local/bin/composer ]]; then
    log "Failed to install composer" "WARN"
fi
