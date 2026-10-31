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

# Install apache, supervisor and watchdog
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        apache2 \
        openssl \
        ssl-cert \
        supervisor \
        python3 \
        python3-watchdog && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install packages
COPY ./apache/packages /root/packages
RUN apt-get update && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/packages && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Apache configuration
COPY ./apache/config/000-default-ssl.conf /etc/apache2/sites-available/000-default-ssl.conf
RUN echo "ServerName $SERVERNAME" > /etc/apache2/conf-available/servername.conf && \
    echo -e "ErrorLog /dev/stderr\nCustomLog /dev/stdout combined" > /etc/apache2/conf-available/redirected-logs.conf && \
    echo "IncludeOptional php-fpm-sites/*.conf" > /etc/apache2/sites-available/php-fpm-sites.conf

RUN a2enmod proxy \
            proxy_fcgi \
            rewrite \
            setenvif \
            ssl

RUN a2enconf servername  && \
    a2enconf redirected-logs && \
    a2ensite php-fpm-sites && \
    a2disconf other-vhosts-access-log

# Supervisor configuration
RUN mkdir -p /var/log/supervisor \
             /var/run/apache2
COPY ./apache/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Entrypoint scripts
COPY --chmod=755 ./apache/entrypoint.sh /docker/entrypoint.sh
COPY --chmod=755 ./apache/entrypoint.d/ /docker/entrypoint.d/

EXPOSE 80 443

ENTRYPOINT ["/bin/bash", "/docker/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
