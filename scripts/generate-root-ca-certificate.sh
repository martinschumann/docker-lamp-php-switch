#!/usr/bin/env bash
set -euo pipefail

source /opt/pki/bin/utils.sh

assert_envs PKI_DIR \
            ROOT_CA_CONF_FILE_PATH \
            ROOT_CA_KEY_FILE_PATH \
            ROOT_CA_CERT_FILE_PATH \
            RENEW_SSL_CA

assert_files "$ROOT_CA_CONF_FILE_PATH"

# if [[ ! -f "$ROOT_CA_CONF_FILE_PATH" ]]; then
#     log "Config file for generating root CA certificate is missing." "ERROR"
#     exit 1
# fi

if [[ ! -f "$ROOT_CA_CERT_FILE_PATH" ]] || [[ "$RENEW_SSL_CA" -gt 0 ]]; then
    log "Generating Root-CA certificate." && \
    openssl ecparam -genkey \
                    -name prime256v1 \
                    -noout \
                    -out "$ROOT_CA_KEY_FILE_PATH" && \
    chmod 600 "$ROOT_CA_KEY_FILE_PATH" && \
    openssl req -new \
                -x509 \
                -newkey ec:prime256v1 \
                -key "$ROOT_CA_KEY_FILE_PATH" \
                -config "$ROOT_CA_CONF_FILE_PATH" \
                -out "$ROOT_CA_CERT_FILE_PATH"
fi
