#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    . "$SCRIPT_DIR/common.sh"
else
    . /usr/local/bin/common.sh
fi

if [ ! -f "$XRAY_CONFIG" ]; then
    err "config not found at ${XRAY_CONFIG}."
    exit 1
fi

UUID=$(xray_uuid) || UUID=""

if [ -z "$UUID" ]; then
    err "UUID not found in config."
    exit 1
fi

if [ -z "${CODESPACE_NAME:-}" ]; then
    warn "CODESPACE_NAME is not set; the SNI in the link will be incomplete."
fi

SNI="${CODESPACE_NAME:-}-443.app.github.dev"
LINK="vless://${UUID}@94.130.50.12:443?encryption=none&security=tls&sni=${SNI}&host=${SNI}&fp=chrome&allowInsecure=1&type=xhttp&mode=packet-up&path=%2F#nikvpn-codespace"

echo ""
echo "========================================"
echo "🔗 NikVPN - Your VLESS xHTTP Link"
echo "========================================"
echo "${LINK}"
echo ""
echo "📌 Make sure port 443 is PUBLIC (check PORTS tab)"
echo "========================================"
echo ""
