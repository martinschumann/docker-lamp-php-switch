#!/usr/bin/env bash
set -euo pipefail

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

assert_files "/opt/pki/root-ca/conf/root-ca.lamp-php-switch.cnf"

# Generate Root-CA certificate
if [[ ! -f "/docker/ca/.initialized" ]] || [[ "${RENEW_SSL_CA:-0}" -gt 0 ]]; then
    log "Generating Root-CA certificate." && \
    openssl ecparam -genkey \
                    -name prime256v1 \
                    -noout \
                    -out "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" && \
    chmod 600 "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" && \
    openssl req -new \
                -x509 \
                -newkey ec:prime256v1 \
                -key "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" \
                -config "/opt/pki/root-ca/conf/root-ca.lamp-php-switch.cnf" \
                -out "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt";

    assert_files "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt";

    cp "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" "/docker/ca/" && \
    cp "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt" "/docker/ca/" && \
    touch "/docker/ca/.initialized";
fi

assert_files "/docker/ca/root-ca.lamp-php-switch.key" "/docker/ca/root-ca.lamp-php-switch.crt"

# Reimport into PKI
cp "/docker/ca/root-ca.lamp-php-switch.key" "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" && \
chmod 600 "/opt/pki/root-ca/private/root-ca.lamp-php-switch.key" && \
cp "/docker/ca/root-ca.lamp-php-switch.crt" "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt";

cp "/opt/pki/root-ca/certs/root-ca.lamp-php-switch.crt" "/usr/local/share/ca-certificates/" && \
update-ca-certificates
