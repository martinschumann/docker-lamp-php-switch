#!/usr/bin/env bash
set -euo pipefail

source /opt/pki/bin/utils.sh

assert_envs ROOT_CA_KEY_FILE_PATH \
            ROOT_CA_CERT_FILE_PATH \
            CSR_FILE_PATH \
            CONF_FILE_PATH \
            KEY_FILE_PATH \
            CERT_FILE_PATH \
            RENEW_SSL_CA \
            RENEW_SSL_CERT

assert_files "$ROOT_CA_KEY_FILE_PATH" \
             "$ROOT_CA_CERT_FILE_PATH"

common_name=$(grep -m 1 "^[[:space:]]*CN[[:space:]]*=" "$CONF_FILE_PATH" | sed 's/.*=[[:space:]]*//')

if [[ -z "$common_name" ]]; then
    log "Common name not found in config file $CONF_FILE" "ERROR"
    exit 1
fi

log "Generating SSL certificate for ${common_name}"
openssl genpkey -algorithm EC \
                -pkeyopt ec_paramgen_curve:prime256v1 \
                -out "$KEY_FILE_PATH" && \
openssl req -new \
            -config "$CONF_FILE_PATH" \
            -key "$KEY_FILE_PATH" \
            -reqexts v3_req \
            -out "$CSR_FILE_PATH" 2>&1 && \
openssl x509 -req \
             -CA "$ROOT_CA_CERT_FILE_PATH" \
             -CAkey "$ROOT_CA_KEY_FILE_PATH" \
             -CAcreateserial \
             -copy_extensions copy \
             -days 365 \
             -in "$CSR_FILE_PATH" \
             -out "$CERT_FILE_PATH" 2>&1

if [[ $(get_key_checksum "$KEY_FILE_PATH") != $(get_cert_checksum "$CERT_FILE_PATH") ]]; then
    log "SSL certificate and key do not match!" "ERROR"
fi
