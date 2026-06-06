#!/usr/bin/env bash

set -e

if [[ ! -f "/opt/pki/private/lamp.localhost-rootCA.key" ]] || [[ "${RENEW_SSL_CERT_ON_BUILD}" ]]; then
    echo "Generating Root-CA certificate"
    openssl genrsa -out /opt/pki/private/lamp.localhost-rootCA.key 4096 && \
    chmod 600 /opt/pki/private/lamp.localhost-rootCA.key && \
    openssl req -config /opt/pki/lamp.localhost-ca.cnf \
                -key /opt/pki/private/lamp.localhost-rootCA.key \
                -new -x509 \
                -days 3650 \
                -sha256 \
                -extensions v3_ca \
                -out /opt/pki/certs/lamp.localhost-rootCA.crt && \
    cp /opt/pki/certs/lamp.localhost-rootCA.crt /usr/local/share/ca-certificates/lamp.localhost-rootCA.crt && \
    update-ca-certificates

    openssl genrsa -out /opt/pki/private/wildcard.lamp.localhost.key 2048 && \
    openssl req -new \
                -key /opt/pki/private/wildcard.lamp.localhost.key \
                -out /opt/pki/csr/wildcard.lamp.localhost.csr \
                -subj "/C=DE/ST=Hamburg/L=Hamburg/O=lamp-php-switch/CN=lamp.localhost"

    openssl x509 -req \
                 -in /opt/pki/csr/wildcard.lamp.localhost.csr\
                 -CA /opt/pki/certs/lamp.localhost-rootCA.crt \
                 -CAkey /opt/pki/private/lamp.localhost-rootCA.key \
                 -CAcreateserial \
                 -out /opt/pki/certs/wildcard.lamp.localhost.crt \
                 -days 825 \
                 -sha256 \
                 -extfile /opt/pki/csr/wildcard.lamp.localhost.san.cnf

    /usr/local/bin/store-certs-on-host.sh

    a2enmod ssl && \
    a2ensite include-fpm-sites && \
    a2ensite 000-default-ssl
fi

exec "$@"



