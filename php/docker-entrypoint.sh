#!/usr/bin/env bash

set -eu

echo "Running entrypoint script $(hostname):$(realpath ${BASH_SOURCE[0]})"

if [[ "$(id -u)" = "0" ]]; then
    # Change the ubuntu user’s UID to match the host UID.
    if [[ ! $(id "${HOST_UID}" 2>/dev/null) ]]; then
        usermod -u "${HOST_UID}" ubuntu \
            && echo "Changed the ubuntu user’s UID to match the host UID ${HOST_UID}"
    fi;

    socat TCP4-LISTEN:3306,bind=127.0.0.1,fork TCP4:172.16.1.12:3306 &

    if [[ -d /home/ubuntu/.host-data/ ]]; then
        sudo -u ubuntu touch /home/ubuntu/.host-data/.gitconfig
        sudo -u ubuntu touch /home/ubuntu/.host-data/.bash_history

        if [[ ! -f /home/ubuntu/.gitconfig ]]; then
            sudo -u ubuntu ln -sr /home/ubuntu/.host-data/.gitconfig /home/ubuntu/.gitconfig
        fi

        if [[ ! -f /home/ubuntu/.bash_history ]]; then
            sudo -u ubuntu ln -sr /home/ubuntu/.host-data/.bash_history /home/ubuntu/.bash_history
        fi

        if [[ ! -f /home/ubuntu/vhosts ]]; then
            sudo -u ubuntu ln -sr /srv/apache2/vhosts /home/ubuntu/
        fi
    fi

fi;

exec "$@"
