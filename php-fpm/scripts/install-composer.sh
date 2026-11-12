#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

expected_checksum="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
actual_checksum="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [[ "$expected_checksum" != "$actual_checksum" ]]; then
    rm composer-setup.php
    log "Invalid installer checksum" "ERROR"
fi

php composer-setup.php --quiet --install-dir=/usr/local/bin/ --filename=composer
result=$?
rm composer-setup.php

if [[ "$result" -gt 0 ]] || [[ ! -f /usr/local/bin/composer ]]; then
    log "Failed to install composer" "WARN"
else
    version="$(composer --version --no-ansi 2>/dev/null | egrep -o '[0-9]+[\.][0-9]+[\.][0-9]+')"
    log "Installed composer $version"
fi
