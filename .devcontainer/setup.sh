#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    . "$SCRIPT_DIR/common.sh"
else
    . /usr/local/bin/common.sh
fi

FALLBACK_VERSION="v26.3.27"

LATEST=$(curl -fsSL "https://api.github.com/repos/XTLS/Xray-core/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4) || LATEST=""

if [ -z "$LATEST" ]; then
    warn "could not resolve latest Xray release, using ${FALLBACK_VERSION}"
    LATEST="$FALLBACK_VERSION"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

log "Downloading Xray ${LATEST}..."
download "https://github.com/XTLS/Xray-core/releases/download/${LATEST}/Xray-linux-64.zip" "${TMPDIR}/xray.zip"

if ! unzip -q "${TMPDIR}/xray.zip" -d "${TMPDIR}"; then
    err "failed to extract Xray archive"
    exit 1
fi

if [ ! -f "${TMPDIR}/xray" ]; then
    err "xray binary missing from downloaded archive"
    exit 1
fi

install -m 755 "${TMPDIR}/xray" /usr/local/bin/xray

log "Downloading GeoIP..."
download "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" /usr/local/bin/geoip.dat

log "Downloading GeoSite..."
download "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" /usr/local/bin/geosite.dat

if [ ! -f "$XRAY_CONFIG" ]; then
    err "config not found at ${XRAY_CONFIG}"
    exit 1
fi

UUID=$(uuidgen)
if [ -z "$UUID" ]; then
    err "failed to generate UUID"
    exit 1
fi

if ! grep -q "PLACEHOLDER_UUID" "$XRAY_CONFIG"; then
    err "PLACEHOLDER_UUID not found in ${XRAY_CONFIG}"
    exit 1
fi

sed -i "s/PLACEHOLDER_UUID/${UUID}/" "$XRAY_CONFIG"

if grep -q "PLACEHOLDER_UUID" "$XRAY_CONFIG"; then
    err "failed to substitute UUID in ${XRAY_CONFIG}"
    exit 1
fi

log "Setup complete. Xray ${LATEST} installed with UUID: ${UUID}"
