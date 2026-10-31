#!/usr/bin/env bash
set -euo pipefail

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

if [[ "$(id -u)" = "0" ]]; then
    # Change the ubuntu user’s UID to match the host UID.
    if [[ ! $(id "${HOST_UID}" 2>/dev/null) ]]; then
        log "Change the ubuntu user’s UID to match the host UID ${HOST_UID}"
        usermod -u "${HOST_UID}" ubuntu
    fi;

    # Create writeable files on bind mount
    if [[ -d /home/ubuntu/.host-data/ ]]; then
        log "Create writeable files for user-account on bind mount"

        sudo -u ubuntu touch /home/ubuntu/.host-data/.gitconfig
        sudo -u ubuntu touch /home/ubuntu/.host-data/.bash_history

        if [[ ! -e /home/ubuntu/.gitconfig ]]; then
            sudo -u ubuntu ln -sr /home/ubuntu/.host-data/.gitconfig /home/ubuntu/.gitconfig
        fi

        if [[ ! -e /home/ubuntu/.bash_history ]]; then
            sudo -u ubuntu ln -sr /home/ubuntu/.host-data/.bash_history /home/ubuntu/.bash_history
        fi

        if [[ ! -e /home/ubuntu/vhosts ]]; then
            sudo -u ubuntu ln -sr /srv/apache2/vhosts /home/ubuntu/
        fi
    fi
fi;
