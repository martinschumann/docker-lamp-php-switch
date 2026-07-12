#!/usr/bin/env bash
set -euo pipefail

current_ssl_build_stamp=$(cat /etc/ssl/conf/.ssl_build_stamp 2>/dev/null || echo "0")

# Create directories for SSL certificate self-signed by self-generated Root-CA
mkdir -p /opt/pki/certs \
         /opt/pki/crl \
         /opt/pki/csr \
         /opt/pki/private && \
chmod 700 /opt/pki/private

root_ca_key="/opt/pki/private/lamp.localhost-rootCA.key"
root_ca_cert="/opt/pki/certs/lamp.localhost-rootCA.crt"

ca_conf="/etc/ssl/conf/CA_lamp.localhost.cnf"
wildcard_cert_conf="/etc/ssl/conf/csr/wildcard.lamp.localhost.san.cnf"
request_conf="/etc/ssl/conf/csr/req.cnf"

signing_req="/opt/pki/csr/wildcard.lamp.localhost.csr"

wildcard_key="/opt/pki/private/wildcard.lamp.localhost.key"
wildcard_cert="/opt/pki/certs/wildcard.lamp.localhost.crt"

if [[ -f "$ca_conf" ]] \
    && [[ -f "$wildcard_cert_conf" ]] \
    && [[ -f "$request_conf" ]] \
    && (( SSL_BUILD_STAMP > current_ssl_build_stamp || current_ssl_build_stamp == 0 )); then
        cat << 'EOF'
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Generating Root-CA certificate.
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

        openssl genrsa -out "$root_ca_key" 4096 && \
        chmod 600 "$root_ca_key" && \
        openssl req -config "$ca_conf" \
                    -key "$root_ca_key" \
                    -new -x509 \
                    -days 3650 \
                    -sha256 \
                    -extensions v3_ca \
                    -out "$root_ca_cert"

        cat << 'EOF'
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Generating SSL certificate for lamp.localhost.
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF

        openssl genrsa -out "$wildcard_key" 2048 && \
        openssl req -new \
                    -key "$wildcard_key" \
                    -out "$signing_req" \
                    -config "$request_conf"

        openssl x509 -req \
                     -in "$signing_req" \
                     -CA "$root_ca_cert" \
                     -CAkey "$root_ca_key" \
                     -CAcreateserial \
                     -out "$wildcard_cert" \
                     -days 825 \
                     -sha256 \
                     -extfile "$wildcard_cert_conf"

        echo -n "$SSL_BUILD_STAMP" > /etc/ssl/conf/.ssl_build_stamp
fi

if [[ ! -f "$ca_conf" || ! -f "$wildcard_cert_conf" || ! -f "$request_conf" ]]; then
    cat << 'EOF'
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ERROR: Config files for generating SSL-Certificates are missting.
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
    exit 1
fi

if (( SSL_BUILD_STAMP == current_ssl_build_stamp)); then
    cat << 'EOF'
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
SSL_BUILD_STAMP not renewed and certification renewal not requested.
Exiting without any action.
SSL_BUILD_STAMP: "$SSL_BUILD_STAMP"
current_ssl_build_stamp: "$current_ssl_build_stamp"
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EOF
fi

exit 0
