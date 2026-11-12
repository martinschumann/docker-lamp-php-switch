#!/usr/bin/env bash
set -euo pipefail

source /docker/lib/utils.sh

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

socat TCP4-LISTEN:3306,bind=127.0.0.1,reuseaddr,fork TCP4:mariadb:3306 &
