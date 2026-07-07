#!/bin/sh
# Shared helpers and constants for the NikVPN devcontainer scripts.
# Source this file from other scripts: . /usr/local/bin/common.sh

NIKVPN_PREFIX="[NikVPN]"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"

# log MESSAGE... -> print a prefixed status line to stdout.
log() {
    echo "${NIKVPN_PREFIX} $*"
}

# warn MESSAGE... -> print a prefixed warning line to stderr.
warn() {
    echo "${NIKVPN_PREFIX} Warning: $*" >&2
}

# err MESSAGE... -> print a prefixed error line to stderr.
err() {
    echo "${NIKVPN_PREFIX} Error: $*" >&2
}

# download URL DEST -> fetch URL to DEST, failing loudly on HTTP/network errors.
# -f makes curl return non-zero on HTTP >= 400 (otherwise an error page is
# silently written to DEST), -S surfaces the error, and --retry handles flakes.
download() {
    if ! curl -fSL --retry 3 --retry-delay 2 "$1" -o "$2"; then
        err "failed to download $1"
        return 1
    fi
}

# xray_uuid -> print the first client UUID found in the xray config.
xray_uuid() {
    grep -o '"id": *"[^"]*"' "$XRAY_CONFIG" | head -1 | grep -o '"[^"]*"$' | tr -d '"'
}
