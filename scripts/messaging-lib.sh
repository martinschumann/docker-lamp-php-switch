#!/bin/bash

set -euo pipefail

echo_info()    { echo -e "\033[1;34m[INFO]\033[0m    ${*}"; }
echo_success() { echo -e "\033[1;32m[SUCCESS]\033[0m ${*}"; }
echo_warn()    { echo -e "\033[1;33m[WARN]\033[0m    ${*}"; }
echo_error()   { echo -e "\033[1;31m[ERROR]\033[0m   ${*}"; }
