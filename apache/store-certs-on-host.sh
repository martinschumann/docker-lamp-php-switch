#!/usr/bin/env bash
set -euo pipefail

log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    local line

    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

    # Replace linefeeds with a safe character sequence
    message="${message//$'\n'/\\n}"
    message="${message//$'\r'/\\r}"

    line=$(printf "[%s] [ENTRYPOINT] [%s] %s\n" "$timestamp" "$level" "$message")

    if [[ "$level" == "ERROR" || "$level" == "WARN" ]]; then
        printf "%s\n" "$line" >&2
    else
        printf "%s\n" "$line"
    fi
}

root_ca_file="/opt/pki/certs/lamp.localhost-rootCA.crt"
key_file="/opt/pki/private/wildcard.lamp.localhost.key"
cert_file="/opt/pki/certs/wildcard.lamp.localhost.crt"

root_ca_host_file="/etc/ssl/export/lamp.localhost-rootCA.crt"
cert_host_file="/etc/ssl/export/wildcard.lamp.localhost.crt"

chained_certificate_host_file="/etc/ssl/export/ca-bundle.pem"

# SSL cert and chained certificate are dependants of Root-CA generation.
# Therefore skipping further checks is reasonable.
if [[ -f "$root_ca_file" ]] \
    && [[ ! -f "$root_ca_host_file" ]]; then
        log "INFO" "Storing Root-CA certificate on host."
        cp "$root_ca_file" "$root_ca_host_file"

        log "INFO" "Storing SSL certificate on host."
        cat "$cert_file" > "$cert_host_file"

        log "INFO" "Storing chained certificate on host."
        cat "$cert_file" > "$chained_certificate_host_file" && \
        cat "$root_ca_file" >> "$chained_certificate_host_file"
fi

if [[ -f "$root_ca_file" ]] \
    && [[ -f "$root_ca_host_file" ]] \
    && ! cmp -s "$root_ca_file" "$root_ca_host_file"; then
        log "INFO" "Updating Root-CA certificate on host."
        cat "$root_ca_file" > "$root_ca_host_file"

        log "INFO" "Updating SSL certificate on host."
        cat "$cert_file" > "$cert_host_file"

        log "INFO" "Updating chained certificate on host."
        cat "$cert_file" > "$chained_certificate_host_file" && \
        cat "$root_ca_file" >> "$chained_certificate_host_file"
fi

if [[ -f "$key_file" && -f "$cert_file" ]]; then
        log "INFO" "Switching Apache to custom 000-default-ssl config …"
        a2dissite default-ssl
        a2ensite 000-default-ssl
    else
        log "INFO" "Using Apache default-ssl base configuration …"
        a2ensite default-ssl
        a2dissite 000-default-ssl
fi

if [[ -f "$root_ca_file" ]]; then
    cp -f "$root_ca_file" /usr/local/share/ca-certificates/
    update-ca-certificates
fi

exec "$@"
