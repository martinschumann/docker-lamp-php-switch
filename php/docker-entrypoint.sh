#!/usr/bin/env bash

set -e

echo "Running entrypoint script $(hostname):$(realpath ${BASH_SOURCE[0]})"

if [ "$(id -u)" = "0" ]; then
    # Change the ubuntu user’s UID to match the host UID.
    if [ ! $(id ${HOST_UID} 2>/dev/null) ]; then
        usermod -u "${HOST_UID}" ubuntu && echo "Change the ubuntu user’s UID to match the host UID ${HOST_UID}"
    fi;

    socat TCP4-LISTEN:3306,bind=127.0.0.1,fork TCP4:172.16.1.12:3306 &
fi;

sudo -u ubuntu ln -sr /srv/apache2/vhosts /home/ubuntu/

exec "$@"
