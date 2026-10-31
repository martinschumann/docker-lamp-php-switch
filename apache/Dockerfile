###############################################################
FROM martinschumann/docker-lamp-php-switch-pki:latest AS apache
###############################################################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG SERVERNAME=apache \
    PHP_VERSION

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

RUN ln -sf /dev/stdout /var/log/apache2/access.log && \
    ln -sf /dev/stderr /var/log/apache2/error.log

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
RUN echo "IncludeOptional php-fpm-sites/*.conf" > /etc/apache2/sites-available/php-fpm-sites.conf && \
    a2ensite php-fpm-sites

RUN mkdir -p /var/log/supervisor \
             /var/run/apache2
COPY ./apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY --chmod=755 ./apache/entrypoint.sh /docker/entrypoint.sh
COPY --chmod=755 ./apache/entrypoint.d/ /docker/entrypoint.d/

EXPOSE 80 443

ENTRYPOINT ["/bin/bash", "/docker/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
