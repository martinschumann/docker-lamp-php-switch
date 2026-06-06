FROM ubuntu:24.04

ARG SERVERNAME='apache'
ARG RENEW_SSL_CERT_ON_BUILD

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV RENEW_SSL_CERT_ON_BUILD=${RENEW_SSL_CERT_ON_BUILD}

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -euxo pipefail && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        apache2 \
        openssl \
        supervisor \
        python3 \
        python3-watchdog
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN a2enmod proxy proxy_fcgi setenvif

# Install packages
COPY ./apache/packages /root/packages
RUN set -euxo pipefail && \
    apt-get update && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/packages && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Generate SSL certificate self-signed by self-generated 
RUN mkdir -p /opt/pki/certs \
             /opt/pki/crl \
             /opt/pki/csr \
             /opt/pki/private && \
    chmod 700 /opt/pki/private

COPY ./apache/ssl/conf/lamp.localhost-ca.cnf /opt/pki/lamp.localhost-ca.cnf
COPY ./apache/ssl/conf/wildcard.lamp.localhost.san.cnf /opt/pki/csr/wildcard.lamp.localhost.san.cnf
COPY ./apache/store-certs-on-host.sh /usr/local/bin/store-certs-on-host.sh
RUN chmod +x /usr/local/bin/store-certs-on-host.sh

COPY ./apache/000-default-ssl.conf /etc/apache2/sites-available/000-default-ssl.conf
COPY ./apache/elements/ssl-common.conf /etc/apache2/elements/ssl-common.conf

RUN echo "IncludeOptional fpm-sites/*.conf" > /etc/apache2/sites-available/include-fpm-sites.conf
RUN echo "ServerName $SERVERNAME" > /etc/apache2/conf-available/servername.conf
RUN a2enconf servername  && \
    a2enmod rewrite  && \
    a2disconf other-vhosts-access-log

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/run/apache2
COPY ./apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

COPY ./apache/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
EXPOSE 80 443

######

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
