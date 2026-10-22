#!/usr/bin/env bash
set -euo pipefail

source /opt/pki/bin/utils.sh

assert_envs ROOT_CA_CERT_FILE \
            ROOT_CA_CERT_FILE_PATH \
            KEY_FILE_PATH \
            CERT_FILE_PATH \
            KEY_FILE \
            CERT_FILE \
            APACHE_SSL_DIR

ca_exported=false

# Root CA certificate
if [[ -f "$ROOT_CA_CERT_FILE_PATH" ]] \
    && [[ ! -f "$APACHE_SSL_DIR/$ROOT_CA_CERT_FILE" ]]; then
    cp "$ROOT_CA_CERT_FILE_PATH" "$APACHE_SSL_DIR"
    log "Stored Root-CA certificate in ${APACHE_SSL_DIR}"
    ca_exported=true
fi

if [[ -f "$ROOT_CA_CERT_FILE_PATH" ]] \
    && [[ -f "$APACHE_SSL_DIR/$ROOT_CA_CERT_FILE" ]] \
    && ! cmp -s "$ROOT_CA_CERT_FILE_PATH" "$APACHE_SSL_DIR/$ROOT_CA_CERT_FILE"; then
        cp -f "$ROOT_CA_CERT_FILE_PATH" "$APACHE_SSL_DIR"
        log "Updated Root-CA certificate in ${APACHE_SSL_DIR}"
        ca_exported=true
fi

# Server certificate
if [[ $ca_exported ]]; then
    assert_files "$KEY_FILE_PATH" \
                 "$CERT_FILE_PATH"

    if [[ -f "$APACHE_SSL_DIR/$CERT_FILE" ]]; then
        if ! cmp -s "$CERT_FILE_PATH" "$APACHE_SSL_DIR/$CERT_FILE"; then
            cp -f "$KEY_FILE_PATH" "$APACHE_SSL_DIR"
            cp -f "$CERT_FILE_PATH" "$APACHE_SSL_DIR"
            log "Updated SSL certificate and key in ${APACHE_SSL_DIR}"
        fi
    else
        cp -f "$KEY_FILE_PATH" "$APACHE_SSL_DIR/$KEY_FILE"
        cp -f "$CERT_FILE_PATH" "$APACHE_SSL_DIR/$CERT_FILE"
        log "Stored SSL certificate and key in ${APACHE_SSL_DIR}"
    fi

    if [[ $(get_key_checksum "$APACHE_SSL_DIR/$KEY_FILE") != $(get_cert_checksum "$APACHE_SSL_DIR/$CERT_FILE") ]]; then
        log "SSL certificate and key do not match!" "ERROR"
    fi
fi
