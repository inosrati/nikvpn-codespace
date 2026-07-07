#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    . "$SCRIPT_DIR/common.sh"
else
    . /usr/local/bin/common.sh
fi

LATEST=$(curl -sL "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
    LATEST="v26.3.27"
fi

TMPDIR="$(mktemp -d)"

log "Downloading Xray ${LATEST}..."
download "https://github.com/XTLS/Xray-core/releases/download/${LATEST}/Xray-linux-64.zip" "${TMPDIR}/xray.zip"
unzip -q "${TMPDIR}/xray.zip" -d "${TMPDIR}"
install -m 755 "${TMPDIR}/xray" /usr/local/bin/xray

log "Downloading GeoIP..."
download "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" /usr/local/bin/geoip.dat

log "Downloading GeoSite..."
download "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" /usr/local/bin/geosite.dat

UUID=$(uuidgen)
sed -i "s/PLACEHOLDER_UUID/${UUID}/" "$XRAY_CONFIG"

rm -rf "${TMPDIR}"
log "Setup complete. Xray ${LATEST} installed with UUID: ${UUID}"
