#!/usr/bin/env bash

set -eu

if [[ -f /opt/pki/certs/wildcard.lamp.localhost.crt ]]; then
    cat /opt/pki/certs/wildcard.lamp.localhost.crt > /etc/ssl/export/wildcard.lamp.localhost.crt
fi

if [[ -f /opt/pki/certs/wildcard.lamp.localhost.crt && -f /opt/pki/certs/lamp.localhost-rootCA.crt ]]; then
    cat /opt/pki/certs/lamp.localhost-rootCA.crt > /etc/ssl/export/wildcard.lamp.localhost.pem && \
    cat /opt/pki/certs/wildcard.lamp.localhost.crt >> /etc/ssl/export/wildcard.lamp.localhost.pem && \
    cat /opt/pki/certs/lamp.localhost-rootCA.crt > /etc/ssl/export/lamp.localhost-rootCA.crt
fi
