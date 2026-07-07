#!/bin/sh
# Shared helpers and constants for the NikVPN devcontainer scripts.
# Source this file from other scripts: . /usr/local/bin/common.sh

NIKVPN_PREFIX="[NikVPN]"
XRAY_CONFIG="${XRAY_CONFIG:-/etc/xray/config.json}"

# log MESSAGE... -> print a prefixed status line to stdout.
log() {
    echo "${NIKVPN_PREFIX} $*"
}

# err MESSAGE... -> print a prefixed error line to stderr.
err() {
    echo "${NIKVPN_PREFIX} Error: $*" >&2
}

# download URL DEST -> fetch URL to DEST following redirects, quietly.
download() {
    curl -sL "$1" -o "$2"
}

# xray_uuid -> print the first client UUID found in the xray config.
xray_uuid() {
    grep -o '"id": *"[^"]*"' "$XRAY_CONFIG" | head -1 | grep -o '"[^"]*"$' | tr -d '"'
}
