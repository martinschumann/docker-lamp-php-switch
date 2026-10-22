#!/usr/bin/env bash
set -euo pipefail

source /opt/pki/bin/utils.sh

assert_envs KEY_FILE \
            CERT_FILE \
            APACHE_SSL_DIR

if [[ -f "$APACHE_SSL_DIR/$KEY_FILE" ]] \
    && [[ -f "$APACHE_SSL_DIR/$CERT_FILE" ]] \
    && [[ $(get_key_checksum "$APACHE_SSL_DIR/$KEY_FILE") == $(get_cert_checksum "$APACHE_SSL_DIR/$CERT_FILE") ]]; then
    log "Switching the Apache to custom 000-default-ssl config." "INFO"
    log "$APACHE_SSL_DIR/$KEY_FILE"
    log "$(get_key_checksum "$APACHE_SSL_DIR/$KEY_FILE")"
    log "$APACHE_SSL_DIR/$CERT_FILE"
    log "$(get_cert_checksum "$APACHE_SSL_DIR/$CERT_FILE")"

    a2dissite default-ssl
    a2ensite 000-default-ssl
else
    log "INFO" "Using Apache default-ssl base configuration." "INFO"
    a2ensite default-ssl
    a2dissite 000-default-ssl
fi
