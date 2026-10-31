#!/usr/bin/env bash
set -euo pipefail

log "Running $(hostname):$(realpath ${BASH_SOURCE[0]})"

socat TCP4-LISTEN:3306,bind=127.0.0.1,fork TCP4:172.16.1.12:3306 &
