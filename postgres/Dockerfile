#####################################
FROM postgres:18-bookworm AS postgres
#####################################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends pwgen \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 ./lib/utils.sh /docker/lib/utils.sh
COPY --chmod=755 ./postgres/entrypoint.sh /usr/local/bin/prepended-docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/prepended-docker-entrypoint.sh"]
CMD ["postgres"]
