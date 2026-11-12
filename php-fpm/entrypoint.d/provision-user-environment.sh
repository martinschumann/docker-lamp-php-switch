#!/usr/bin/env bash

(
    set -euo pipefail

    source /docker/lib/utils.sh

    log "Running $(hostname):$(realpath "${BASH_SOURCE[0]}")"

    if [[ "$(id -u)" != 0 ]]; then
        exit 0
    fi

    readonly home_dir=/home/ubuntu
    readonly target_uid="${HOST_UID:-1000}"
    readonly target_gid="${HOST_GID:-1000}"

    if [[ ! "$target_uid" =~ ^[1-9][0-9]*$ ||
          ! "$target_gid" =~ ^[1-9][0-9]*$ ]]; then
        log "HOST_UID and HOST_GID must be positive integers" "ERROR"
        exit 1
    fi

    current_uid="$(id -u ubuntu)"
    current_gid="$(id -g ubuntu)"

    if [[ "$current_uid" != "$target_uid" ]] &&
       getent passwd "$target_uid" >/dev/null; then
        log "Cannot change ubuntu UID to $target_uid. The UID is already in use." "ERROR"
        exit 1
    fi

    if [[ "$current_uid" != "$target_uid" || "$current_gid" != "$target_gid" ]]; then
        if ! getent group "$target_gid" >/dev/null; then
            groupadd --gid "$target_gid" "host-gid-$target_gid"
        fi

        log "Set ubuntu UID to $target_uid and primary GID to $target_gid"

        (
            temporary_home="$(mktemp -d /tmp/ubuntu-home.XXXXXX)"
            trap 'rmdir -- "$temporary_home"' EXIT

            usermod --home "$temporary_home" ubuntu
            trap 'usermod --home "$home_dir" ubuntu && rmdir -- "$temporary_home"' EXIT

            usermod --uid "$target_uid" --gid "$target_gid" ubuntu
        )
    fi


    for path in "$home_dir" \
                "$home_dir/.bashrc" \
                "$home_dir/.bash_logout" \
                "$home_dir/.profile" \
                "$home_dir/.sudo_as_admin_successful"; do
        if [[ -e "$path" && ! -L "$path" ]] && ! mountpoint -q -- "$path"; then
            chown --no-dereference "$target_uid:$target_gid" "$path"
        fi
    done

    if [[ -d "$home_dir/.host-data" ]]; then
        log "Create writable files for ubuntu on the bind mount"

        sudo -u ubuntu touch \
            "$home_dir/.host-data/.gitconfig" \
            "$home_dir/.host-data/.bash_history"

        if [[ ! -e "$home_dir/.gitconfig" && ! -L "$home_dir/.gitconfig" ]]; then
            sudo -u ubuntu ln -sr "$home_dir/.host-data/.gitconfig" "$home_dir/.gitconfig"
        fi

        if [[ ! -e "$home_dir/.bash_history" && ! -L "$home_dir/.bash_history" ]]; then
            sudo -u ubuntu ln -sr "$home_dir/.host-data/.bash_history" "$home_dir/.bash_history"
        fi

        if [[ ! -e "$home_dir/vhosts" && ! -L "$home_dir/vhosts" ]]; then
            sudo -u ubuntu ln -sr /srv/apache2/vhosts "$home_dir/vhosts"
        fi
    fi
)
