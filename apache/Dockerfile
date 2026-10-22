###########################
# apache
FROM ubuntu:24.04 AS apache
###########################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG SERVERNAME=apache \
    PHP_VERSION \
    PKI_DIR \
    ROOT_CA_CONF_FILE \
    ROOT_CA_KEY_FILE \
    ROOT_CA_CERT_FILE \
    CONF_FILE \
    CSR_FILE \
    KEY_FILE \
    CERT_FILE \
    RENEW_SSL_CA \
    RENEW_SSL_CERT \
    APACHE_SSL_DIR

# Validate
RUN : "${PHP_VERSION:?}" \
      "${PKI_DIR:?}" \
      "${ROOT_CA_CONF_FILE:?}" \
      "${ROOT_CA_KEY_FILE:?}" \
      "${ROOT_CA_CERT_FILE:?}" \
      "${CONF_FILE:?}" \
      "${CSR_FILE:?}" \
      "${KEY_FILE:?}" \
      "${CERT_FILE:?}" \
      "${RENEW_SSL_CA:?}" \
      "${RENEW_SSL_CERT:?}" \
      "${APACHE_SSL_DIR:?}"

ENV PHP_VERSION=$PHP_VERSION \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    APACHE_LOG_DIR=/var/log/apache2 \
    APACHE_PID_FILE=/var/run/apache2/apache2.pid \
    APACHE_RUN_DIR=/var/run/apache2 \
    APACHE_LOCK_DIR=/var/lock/apache2

RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        apache2 \
        openssl \
        ssl-cert \
        supervisor \
        python3 \
        python3-watchdog && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
RUN a2enmod proxy proxy_fcgi setenvif

# Install packages
COPY ./apache/packages /root/packages
RUN apt-get update && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/packages && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Apache default configuration
RUN echo "ServerName $SERVERNAME" > /etc/apache2/conf-available/servername.conf
RUN a2enconf servername  && \
    a2enmod rewrite  && \
    a2disconf other-vhosts-access-log && \
    a2enmod ssl

# Apache SSL configuration for selfsigned cert and vhosts proxied to fpm-server
COPY ./apache/config/000-default-ssl.conf /etc/apache2/sites-available/000-default-ssl.conf
RUN echo "IncludeOptional fpm-sites/*.conf" > /etc/apache2/sites-available/include-fpm-sites.conf && \
    a2ensite include-fpm-sites

RUN mkdir -p /var/log/supervisor \
             /var/run/apache2
COPY ./apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

ENV PKI_DIR=$PKI_DIR \
    ROOT_CA_CONF_FILE=$ROOT_CA_CONF_FILE \
    ROOT_CA_KEY_FILE=$ROOT_CA_KEY_FILE \
    ROOT_CA_CERT_FILE=$ROOT_CA_CERT_FILE \
    CONF_FILE=$CONF_FILE \
    CSR_FILE=$CSR_FILE \
    KEY_FILE=$KEY_FILE \
    CERT_FILE=$CERT_FILE \
    ROOT_CA_CONF_FILE_PATH="${PKI_DIR}/root-ca/conf/${ROOT_CA_CONF_FILE}" \
    ROOT_CA_KEY_FILE_PATH="${PKI_DIR}/root-ca/private/${ROOT_CA_KEY_FILE}" \
    ROOT_CA_CERT_FILE_PATH="${PKI_DIR}/root-ca/certs/${ROOT_CA_CERT_FILE}" \
    CONF_FILE_PATH="${PKI_DIR}/conf/${CONF_FILE}" \
    CSR_FILE_PATH="${PKI_DIR}/csr/${CSR_FILE}" \
    KEY_FILE_PATH="${PKI_DIR}/private/${KEY_FILE}" \
    CERT_FILE_PATH="${PKI_DIR}/certs/${CERT_FILE}" \
    APACHE_SSL_DIR="${APACHE_SSL_DIR}"

# Create folder structure
RUN mkdir -p $PKI_DIR/bin \
             $PKI_DIR/root-ca/certs \
             $PKI_DIR/certs \
             $APACHE_SSL_DIR && \
    chmod 700 $APACHE_SSL_DIR

COPY --from=ssl-certs $ROOT_CA_CERT_FILE_PATH $ROOT_CA_CERT_FILE_PATH
COPY --from=ssl-certs $ROOT_CA_CERT_FILE_PATH /usr/local/share/ca-certificates/
RUN update-ca-certificates

COPY --from=ssl-certs $KEY_FILE_PATH $KEY_FILE_PATH
COPY --from=ssl-certs $CERT_FILE_PATH $CERT_FILE_PATH

COPY ./scripts/utils.sh /opt/pki/bin/utils.sh
COPY --chmod=755 ./scripts/export-certs.sh /opt/pki/bin/export-certs.sh
COPY --chmod=755 ./scripts/configure-apache.sh /opt/pki/bin/configure-apache.sh

RUN mkdir -p /docker
COPY --chmod=755 ./apache/entrypoint.sh /docker/entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/bin/bash", "/docker/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
