#!/usr/bin/env bash

set -euo pipefail

root_ca_guest_file="/opt/pki/certs/lamp.localhost-rootCA.crt";
root_ca_host_file="/etc/ssl/export/lamp.localhost-rootCA.crt"
cert_guest_file="/opt/pki/certs/wildcard.lamp.localhost.crt"
cert_host_file="/etc/ssl/export/wildcard.lamp.localhost.crt"
chained_certificate_host_file="/etc/ssl/export/ca-bundle.pem"

# SSL cert and chained certificate are dependants of Root-CA generation
# in entrypoint script. Therefore skipping further checks is accepatable.
if [[ -f "$root_ca_guest_file" ]] \
    && [[ ! -f "$root_ca_host_file" ]]; then
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo "Storing Root-CA certificate on host";
        cp "$root_ca_guest_file" "$root_ca_host_file";

        echo "Storing SSL certificate on host";
        cat "$cert_guest_file" > "$cert_host_file";

        echo "Storing chained certificate on host";
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        cat "$cert_guest_file" > "$chained_certificate_host_file" && \
        cat "$root_ca_guest_file" >> "$chained_certificate_host_file"
fi

if [[ -f "$root_ca_guest_file" ]] \
    && [[ -f "$root_ca_host_file" ]] \
    && [[ $(md5sum "$root_ca_guest_file") != $(md5sum "$root_ca_host_file") ]]; then
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo "Updating Root-CA certificate on host";
        cat "$root_ca_guest_file" > "$root_ca_host_file";

        echo "Updating SSL certificate on host";
        cat "$cert_guest_file" > "$cert_host_file";

        xecho "Updating chained certificate on host";
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        cat "$cert_guest_file" > "$chained_certificate_host_file" && \
        cat "$root_ca_guest_file" >> "$chained_certificate_host_file"
fi
