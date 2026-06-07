#!/usr/bin/env bash

set -euo pipefail

root_ca_key="/opt/pki/private/lamp.localhost-rootCA.key"
root_ca_cert="/opt/pki/certs/lamp.localhost-rootCA.crt";
root_ca_cert_on_host="/etc/ssl/export/lamp.localhost-rootCA.crt"
ca_conf="/opt/pki/CA_lamp.localhost.cnf"

wildcard_key="/opt/pki/private/wildcard.lamp.localhost.key"
wildcard_cert="/opt/pki/certs/wildcard.lamp.localhost.crt"
wildcard_cert_conf="/opt/pki/csr/wildcard.lamp.localhost.san.cnf"
request_conf="/opt/pki/csr/req.cnf"
signing_req="/opt/pki/csr/wildcard.lamp.localhost.csr"

if [[ ! -f "$root_ca_key" ]] \
    || [[ ! -f "$root_ca_cert" ]] \
    || [[ ! -f "$root_ca_cert_on_host" ]] \
    || [[ "${RENEW_SSL_CERT_ON_BUILD}" -eq 1 ]]; then
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo "Generating Root-CA certificate"
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    openssl genrsa -out "$root_ca_key" 4096 && \
    chmod 600 "$root_ca_key" && \
    openssl req -config "$ca_conf" \
                -key "$root_ca_key" \
                -new -x509 \
                -days 3650 \
                -sha256 \
                -extensions v3_ca \
                -out "$root_ca_cert" && \
    cp "$root_ca_cert" /usr/local/share/ca-certificates/ && \
    update-ca-certificates

    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    echo "Generating SSL certificate for lamp.localhost"
    echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    openssl genrsa -out "$wildcard_key" 2048 && \
    openssl req -new \
                -key "$wildcard_key" \
                -out "$signing_req" \
                -config "$request_conf"

                # -subj "/C=DE/ST=Hamburg/L=Hamburg/O=lamp-php-switch/CN=lamp.localhost"

    openssl x509 -req \
                 -in "$signing_req" \
                 -CA "$root_ca_cert" \
                 -CAkey "$root_ca_key" \
                 -CAcreateserial \
                 -out "$wildcard_cert" \
                 -days 825 \
                 -sha256 \
                 -extfile "$wildcard_cert_conf"

    /usr/local/bin/store-certs-on-host.sh
fi

if [[ -f "$wildcard_key" ]] \
    && [[ -f "$wildcard_cert" ]]; then 
    a2ensite include-fpm-sites && \
    a2dissite default-ssl && \
    a2ensite 000-default-ssl
fi;

exec "$@"
