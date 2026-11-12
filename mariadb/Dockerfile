###########################
FROM mariadb:lts AS mariadb
###########################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

COPY --chmod=755 ./lib/utils.sh /docker/lib/utils.sh
COPY --chmod=755 ./mariadb/entrypoint.sh /usr/local/bin/prepended-docker-entrypoint.sh
COPY --chmod=644 ./mariadb/initdb/10-add-root-unix-socket-auth.sh /docker-entrypoint-initdb.d/

ENTRYPOINT ["/usr/local/bin/prepended-docker-entrypoint.sh"]
CMD ["mariadbd"]
