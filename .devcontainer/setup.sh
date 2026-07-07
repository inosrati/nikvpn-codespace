#!/bin/sh
set -eu

LATEST=$(curl -fsL "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
    LATEST="v26.3.27"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

echo "[NikVPN] Downloading Xray ${LATEST}..."
curl -fsL "https://github.com/XTLS/Xray-core/releases/download/${LATEST}/Xray-linux-64.zip" -o "${TMPDIR}/xray.zip"

echo "[NikVPN] Verifying Xray checksum..."
curl -fsL "https://github.com/XTLS/Xray-core/releases/download/${LATEST}/Xray-linux-64.zip.dgst" -o "${TMPDIR}/xray.zip.dgst"
EXPECTED_SHA256=$(grep -i 'SHA2-256' "${TMPDIR}/xray.zip.dgst" | head -1 | awk '{print $2}')
ACTUAL_SHA256=$(sha256sum "${TMPDIR}/xray.zip" | awk '{print $1}')

if [ -z "$EXPECTED_SHA256" ]; then
    echo "[NikVPN] Error: could not read expected SHA-256 checksum." >&2
    exit 1
fi

if [ "$EXPECTED_SHA256" != "$ACTUAL_SHA256" ]; then
    echo "[NikVPN] Error: Xray checksum mismatch!" >&2
    echo "[NikVPN]   expected: ${EXPECTED_SHA256}" >&2
    echo "[NikVPN]   actual:   ${ACTUAL_SHA256}" >&2
    exit 1
fi
echo "[NikVPN] Checksum OK."

unzip -q "${TMPDIR}/xray.zip" -d "${TMPDIR}"
install -m 755 "${TMPDIR}/xray" /usr/local/bin/xray

echo "[NikVPN] Downloading GeoIP..."
curl -fsL "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" -o /usr/local/bin/geoip.dat

echo "[NikVPN] Downloading GeoSite..."
curl -fsL "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" -o /usr/local/bin/geosite.dat

UUID=$(uuidgen)
sed -i "s/PLACEHOLDER_UUID/${UUID}/" /etc/xray/config.json

echo "[NikVPN] Setup complete. Xray ${LATEST} installed with UUID: ${UUID}"
