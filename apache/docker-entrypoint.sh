#!/usr/bin/env bash
set -euo pipefail

root_ca_file="/opt/pki/certs/lamp.localhost-rootCA.crt";
cert_file="/opt/pki/certs/wildcard.lamp.localhost.crt"

root_ca_host_file="/etc/ssl/export/lamp.localhost-rootCA.crt"
cert_host_file="/etc/ssl/export/wildcard.lamp.localhost.crt"

chained_certificate_host_file="/etc/ssl/export/ca-bundle.pem"

# SSL cert and chained certificate are dependants of Root-CA generation
# in entrypoint script. Therefore skipping further checks is accepatable.
if [[ -f "$root_ca_file" ]] \
    && [[ ! -f "$root_ca_host_file" ]]; then
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo "Storing Root-CA certificate on host";
        cp "$root_ca_file" "$root_ca_host_file";

        echo "Storing SSL certificate on host";
        cat "$cert_file" > "$cert_host_file";

        echo "Storing chained certificate on host";
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        cat "$cert_file" > "$chained_certificate_host_file" && \
        cat "$root_ca_file" >> "$chained_certificate_host_file"
fi

if [[ -f "$root_ca_file" ]] \
    && [[ -f "$root_ca_host_file" ]] \
    && ! cmp -s "$root_ca_file" "$root_ca_host_file"; then
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        echo "Updating Root-CA certificate on host";
        cat "$root_ca_file" > "$root_ca_host_file";

        echo "Updating SSL certificate on host";
        cat "$cert_file" > "$cert_host_file";

        echo "Updating chained certificate on host";
        echo "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        cat "$cert_file" > "$chained_certificate_host_file" && \
        cat "$root_ca_file" >> "$chained_certificate_host_file"
fi

exec "$@"
