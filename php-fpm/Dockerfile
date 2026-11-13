############################
FROM ubuntu:24.04 AS php-fpm
############################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Shell login root
COPY ./shell/root/.bashrc.tpl /root/.bashrc

# Shell login user ubuntu
COPY ./shell/ubuntu/.bashrc.tpl /home/ubuntu/.bashrc
COPY ./shell/ubuntu/.sudo_as_admin_successful /home/ubuntu/.sudo_as_admin_successful
RUN chown ubuntu:ubuntu /home/ubuntu/.bashrc && \
    chmod 644 /home/ubuntu/.bashrc && \
    chown ubuntu:ubuntu /home/ubuntu/.sudo_as_admin_successful
COPY --chmod=600 ./shell/sudoers.d/ubuntu /etc/sudoers.d/ubuntu

# Install packages
COPY ./php-fpm/packages.d /root/packages.d
RUN set -euo pipefail && \
    compgen -G "/root/packages.d/*.pkgs" > /dev/null && \
    apt-get update && \
    for file in /root/packages.d/*.pkgs; do \
        xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < "$file"; \
    done && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Configure the Ondřej PHP PPA for Ubuntu 24.04
RUN set -euo pipefail && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL --retry 3 \
        'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14AA40EC0831756778BD28D3FEF00D0089FE6F5C' \
        -o /etc/apt/keyrings/ondrej-php.asc && \
    chmod 0644 /etc/apt/keyrings/ondrej-php.asc && \
    printf '%s\n' \
        'Types: deb' \
        'URIs: https://ppa.launchpadcontent.net/ondrej/php/ubuntu' \
        'Suites: noble' \
        'Components: main' \
        'Signed-By: /etc/apt/keyrings/ondrej-php.asc 14AA40EC0831756778BD28D3FEF00D0089FE6F5C' \
        > /etc/apt/sources.list.d/ondrej-php.sources && \
    rm -rf /var/lib/apt/lists/*

# Install PHP packages
ARG PHP_VERSION
ENV PHP_VERSION=${PHP_VERSION}
COPY ./php-fpm/php-${PHP_VERSION}/php.pkgs /root/php-${PHP_VERSION}.pkgs
RUN set -euo pipefail && \
    apt-get update && \
    xargs -P1 apt-get install -y --no-install-recommends --no-install-suggests < /root/php-${PHP_VERSION}.pkgs  && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    update-alternatives --set php /usr/bin/php${PHP_VERSION} && \
    update-alternatives --set phar /usr/bin/phar${PHP_VERSION}

RUN mkdir -p /srv/php-fpm/log && \
    sed -i "s|error_log = /var/log/php${PHP_VERSION}-fpm.log|error_log = /srv/php-fpm/log/php${PHP_VERSION}-fpm.log|g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf

RUN ln -sf /dev/stderr /srv/php-fpm/log/php${PHP_VERSION}-fpm.log

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
