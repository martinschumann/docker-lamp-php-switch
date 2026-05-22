#!/usr/bin/env bash

set -e

if [[ "${RENEW_SSL_CERT_ON_BUILD}" ]] || [[ -z "$(ls -A /etc/ssl/export/ 2>/dev/null)" ]]; then
    echo "Storing SSL certs on the host."
    /usr/local/bin/store-certs-on-host.sh
fi

exec "$@"
