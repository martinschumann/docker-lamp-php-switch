#!/bin/bash

user="ubuntu"
container="php-fpm"

if [[ $# -gt 0 ]]; then
    user="${1}"
fi

if [[ $# -gt 1 ]]; then
    container="${2}"
fi

docker compose exec --user "${user}" "${container}" /bin/bash -l
