FROM ubuntu:24.04

ARG SERVERNAME='apache'

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -euo pipefail && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        apache2 \
        openssl \
        ssl-cert \
        supervisor \
        python3 \
        python3-watchdog
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod proxy proxy_fcgi setenvif

# Install packages
COPY ./apache/packages /root/packages
RUN set -euo pipefail && \
    apt-get update && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/packages && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Apache default configuration (including SSL)
RUN echo "ServerName $SERVERNAME" > /etc/apache2/conf-available/servername.conf
RUN a2enconf servername  && \
    a2enmod rewrite  && \
    a2disconf other-vhosts-access-log && \
    a2enmod ssl && \
    a2ensite default-ssl

# Create directories for SSL certificate self-signed by self-generated Root-CA
RUN mkdir -p /opt/pki/certs \
             /opt/pki/crl \
             /opt/pki/csr \
             /opt/pki/private && \
    chmod 700 /opt/pki/private

# CA, SAN and Req configurations
COPY ./apache/ssl/conf/CA_lamp.localhost.cnf           /opt/pki/CA_lamp.localhost.cnf
COPY ./apache/ssl/conf/wildcard.lamp.localhost.san.cnf /opt/pki/csr/wildcard.lamp.localhost.san.cnf
COPY ./apache/ssl/conf/req.cnf                         /opt/pki/csr/req.cnf

# Apache SSL configuration for selfsigned cert and vhosts proxied to fpm-server
COPY ./apache/000-default-ssl.conf /etc/apache2/sites-available/000-default-ssl.conf
COPY ./apache/elements/ssl-common.conf /etc/apache2/elements/ssl-common.conf
RUN echo "IncludeOptional fpm-sites/*.conf" > /etc/apache2/sites-available/include-fpm-sites.conf && \
    a2ensite include-fpm-sites

# Generate self-signed cert and use in Apache
COPY ./apache/generate-certs.sh /usr/local/bin/generate-certs.sh

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/run/apache2
COPY ./apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

COPY ./apache/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
EXPOSE 80 443

# Skip cache if renewal wanted
ARG RENEW_SSL_CERT_ON_BUILD
RUN chmod +x /usr/local/bin/generate-certs.sh && \
    if [ ${RENEW_SSL_CERT_ON_BUILD} -gt 0 ]; then /usr/local/bin/generate-certs.sh; fi;

######

ENTRYPOINT ["/bin/bash", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
