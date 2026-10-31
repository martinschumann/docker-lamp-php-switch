#!/usr/bin/env bash
set -euo pipefail

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

if [[ -f "/opt/pki/private/server.lamp-php-switch.key" ]] \
    && [[ -f "/opt/pki/certs/server.lamp-php-switch.crt" ]] \
    && [[ $(get_key_checksum "/opt/pki/private/server.lamp-php-switch.key") == $(get_cert_checksum "/opt/pki/certs/server.lamp-php-switch.crt") ]]; then
    log "Switching the Apache to custom 000-default-ssl config." "INFO"
    a2dissite default-ssl
    a2ensite 000-default-ssl
else
    log "Using Apache default-ssl base configuration." "INFO"
    a2ensite default-ssl
    a2dissite 000-default-ssl
fi
