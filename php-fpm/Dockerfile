############################
# php-fpm
FROM ubuntu:24.04 AS php-fpm
############################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG PHP_VERSION

ENV PHP_VERSION=${PHP_VERSION}

# Install packages
COPY ./php-fpm/packages.d /root/packages.d
RUN set -euo pipefail && \
    compgen -G "/root/packages.d/*.pkgs" > /dev/null && \
    apt-get update && \
    for file in /root/packages.d/*.pkgs; do \
        xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < "$file"; \
    done && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add repository ppa:ondrej/php
RUN rm -rf /root/php-packages
COPY ./php-fpm/php-${PHP_VERSION}/php.pkgs /root/php-${PHP_VERSION}.pkgs
RUN set -euo pipefail && \
    apt-get update && \
    apt-get install software-properties-common -y --no-install-recommends --no-install-suggests && \
    add-apt-repository ppa:ondrej/php  && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/php-${PHP_VERSION}.pkgs  && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    update-alternatives --set php /usr/bin/php${PHP_VERSION} && \
    update-alternatives --set phar /usr/bin/phar${PHP_VERSION}

RUN mkdir -p /srv/php-fpm/log && \
    sed -i "s|error_log = /var/log/php${PHP_VERSION}-fpm.log|error_log = /srv/php-fpm/log/php${PHP_VERSION}-fpm.log|g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

RUN ln -sf /dev/stderr /srv/php-fpm/log/php${PHP_VERSION}-fpm.log

# Shell login root
COPY ./shell/root/.bashrc.tpl /root/.bashrc

# Shell login user ubuntu
COPY ./shell/ubuntu/.bashrc.tpl /home/ubuntu/.bashrc
COPY ./shell/ubuntu/.sudo_as_admin_successful /home/ubuntu/.sudo_as_admin_successful
RUN chown ubuntu:ubuntu /home/ubuntu/.bashrc && \
    chmod 644 /home/ubuntu/.bashrc && \
    chown ubuntu:ubuntu /home/ubuntu/.sudo_as_admin_successful
COPY --chmod=600 ./shell/sudoers.d/ubuntu /etc/sudoers.d/ubuntu

# Utility lib
COPY --chmod=755 ./lib/utils.sh /docker/lib/utils.sh

# Install Composer
COPY --chmod=755 ./php-fpm/scripts/install-composer.sh /docker/bin/install-composer.sh
ARG COMPOSER_CACHE_BUST=0
RUN /docker/bin/install-composer.sh

# Entrypoint scripts
COPY --chmod=755 ./php-fpm/entrypoint.sh /docker/entrypoint.sh
COPY --chmod=755 ./php-fpm/entrypoint.d/ /docker/entrypoint.d/

ENTRYPOINT ["/docker/entrypoint.sh"]
CMD ["/bin/sh", "-c", "php-fpm${PHP_VERSION} -F"]
