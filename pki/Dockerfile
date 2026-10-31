########################
# pki
FROM ubuntu:24.04 AS pki
########################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG RENEW_SSL_CA
ENV RENEW_SSL_CA=$RENEW_SSL_CA

# Install OpenSSL
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        openssl \
        ssl-cert \
        ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create folder structure
RUN mkdir -p /opt/pki/{bin,conf,certs,crl,csr,lib,private,root-ca/{certs,private,conf}} && \
    chmod 700 /opt/pki/{private,root-ca/private}

# Integrate configuration for Roo-CA and server cert
COPY ./pki/conf/root-ca.lamp-php-switch.cnf /opt/pki/root-ca/conf/
COPY ./pki/conf/server.lamp-php-switch.cnf  /opt/pki/conf/

# Integrate libs and entrypoint scripts
COPY --chmod=755 ./lib/utils.sh /docker/lib/utils.sh
COPY --chmod=755 ./pki/entrypoint.sh /docker/entrypoint.sh
COPY --chmod=755 ./pki/entrypoint.d/ /docker/entrypoint.d/

VOLUME /docker/ca

ENTRYPOINT ["/bin/bash", "/docker/entrypoint.sh"]
