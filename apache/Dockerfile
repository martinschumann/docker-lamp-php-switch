########################################
# init-cert-generator
FROM ubuntu:24.04 AS init-cert-generator
########################################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# A requested renewal sets a new timestamp and bursts the cache
ARG SSL_BUILD_STAMP
ENV SSL_BUILD_STAMP=$SSL_BUILD_STAMP

RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        openssl \
        ssl-cert
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./apache/generate-certs.sh /usr/local/bin/generate-certs.sh
RUN chmod +x /usr/local/bin/generate-certs.sh

###############################################
ENTRYPOINT ["/usr/local/bin/generate-certs.sh"]
###############################################

###########################
# apache
FROM ubuntu:24.04 AS apache
###########################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG SSL_BUILD_STAMP
ENV SSL_BUILD_STAMP=$SSL_BUILD_STAMP

ARG SERVERNAME='apache'
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2

RUN apt-get update && \
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
RUN apt-get update && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/packages && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Apache default configuration (including SSL)
RUN echo "ServerName $SERVERNAME" > /etc/apache2/conf-available/servername.conf
RUN a2enconf servername  && \
    a2enmod rewrite  && \
    a2disconf other-vhosts-access-log && \
    a2enmod ssl && \
    a2ensite default-ssl

# Apache SSL configuration for selfsigned cert and vhosts proxied to fpm-server
COPY ./apache/000-default-ssl.conf /etc/apache2/sites-available/000-default-ssl.conf
COPY ./apache/elements/ssl-common.conf /etc/apache2/elements/ssl-common.conf
RUN echo "IncludeOptional fpm-sites/*.conf" > /etc/apache2/sites-available/include-fpm-sites.conf && \
    a2ensite include-fpm-sites

RUN mkdir -p /var/log/supervisor
RUN mkdir -p /var/run/apache2
COPY ./apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

COPY ./apache/store-certs-on-host.sh /usr/local/bin/store-certs-on-host.sh
RUN chmod +x /usr/local/bin/store-certs-on-host.sh
EXPOSE 80 443

###################################################################################
ENTRYPOINT ["/bin/bash", "/usr/local/bin/store-certs-on-host.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
###################################################################################
