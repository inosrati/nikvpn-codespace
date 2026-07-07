#!/bin/bash
set -euo pipefail

CONFIG="/etc/xray/config.json"

if [ ! -f "$CONFIG" ]; then
    echo "[NikVPN] Error: config not found at ${CONFIG}." >&2
    exit 1
fi

UUID=$(grep -o '"id": *"[^"]*"' "$CONFIG" | head -1 | grep -o '"[^"]*"$' | tr -d '"') || UUID=""

if [ -z "$UUID" ]; then
    echo "[NikVPN] Error: UUID not found in config." >&2
    exit 1
fi

if [ -z "${CODESPACE_NAME:-}" ]; then
    echo "[NikVPN] Warning: CODESPACE_NAME is not set; the SNI in the link will be incomplete." >&2
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
