#!/bin/bash

user="ubuntu"
container="php"

if [[ $# -gt 0 ]]; then
    user="${1}"
fi

if [[ $# -gt 1 ]]; then
    container="${2}"
fi

export PHP_VERSION="${PHP_VERSION:-8.4}"
docker compose exec --user "${user}" "${container}" /bin/bash -l
