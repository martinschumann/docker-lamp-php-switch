#!/usr/bin/env bash
set -euo pipefail

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

# Check Root-CA key and cert reimported from /docker/ca/ and server config
assert_files "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" \
             "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt" \
             "/opt/pki/conf/server.lamp-php-switch.cnf"

COMMON_NAME=$(grep -m 1 "^[[:space:]]*CN[[:space:]]*=" "/opt/pki/conf/server.lamp-php-switch.cnf" | sed 's/.*=[[:space:]]*//')

if [[ -z "${COMMON_NAME:-}" ]]; then
    log "Common name not found in config file /opt/pki/conf/server.lamp-php-switch.cnf" "ERROR"
    exit 1
fi

log "Generating SSL certificate for ${COMMON_NAME}"
openssl genpkey -algorithm EC \
                -pkeyopt ec_paramgen_curve:prime256v1 \
                -out "/opt/pki/private/server.lamp-php-switch.key" && \
openssl req -new \
            -config "/opt/pki/conf/server.lamp-php-switch.cnf" \
            -key "/opt/pki/private/server.lamp-php-switch.key" \
            -reqexts v3_req \
            -out "/opt/pki/csr/server.lamp-php-switch.csr" 2>&1 && \
openssl x509 -req \
             -CA "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt" \
             -CAkey "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" \
             -CAcreateserial \
             -copy_extensions copy \
             -days 365 \
             -in "/opt/pki/csr/server.lamp-php-switch.csr" \
             -out "/opt/pki/certs/server.lamp-php-switch.crt" 2>&1
