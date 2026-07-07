#!/bin/sh
set -eu

CONFIG="/etc/xray/config.json"
FALLBACK_VERSION="v26.3.27"

# Download a URL to a destination, failing loudly on HTTP or network errors.
# curl's -f makes it return non-zero on HTTP >= 400 (otherwise an error page
# is silently written to the destination), and -S surfaces the error message.
download() {
    url="$1"
    dest="$2"
    if ! curl -fSL --retry 3 --retry-delay 2 "$url" -o "$dest"; then
        echo "[NikVPN] Error: failed to download ${url}" >&2
        return 1
    fi
}

LATEST=$(curl -fsSL "https://api.github.com/repos/XTLS/Xray-core/releases/latest" \
    | grep '"tag_name"' | cut -d'"' -f4) || LATEST=""

if [ -z "$LATEST" ]; then
    echo "[NikVPN] Warning: could not resolve latest Xray release, using ${FALLBACK_VERSION}" >&2
    LATEST="$FALLBACK_VERSION"
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "[NikVPN] Downloading Xray ${LATEST}..."
download "https://github.com/XTLS/Xray-core/releases/download/${LATEST}/Xray-linux-64.zip" "${TMPDIR}/xray.zip"

echo "[NikVPN] Verifying Xray checksum..."
download "https://github.com/XTLS/Xray-core/releases/download/${LATEST}/Xray-linux-64.zip.dgst" "${TMPDIR}/xray.zip.dgst"
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

if ! unzip -q "${TMPDIR}/xray.zip" -d "${TMPDIR}"; then
    echo "[NikVPN] Error: failed to extract Xray archive" >&2
    exit 1
fi

if [ ! -f "${TMPDIR}/xray" ]; then
    echo "[NikVPN] Error: xray binary missing from downloaded archive" >&2
    exit 1
fi

install -m 755 "${TMPDIR}/xray" /usr/local/bin/xray

echo "[NikVPN] Downloading GeoIP..."
download "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" /usr/local/bin/geoip.dat

echo "[NikVPN] Downloading GeoSite..."
download "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" /usr/local/bin/geosite.dat

if [ ! -f "$CONFIG" ]; then
    echo "[NikVPN] Error: config not found at ${CONFIG}" >&2
    exit 1
fi

UUID=$(uuidgen)
if [ -z "$UUID" ]; then
    echo "[NikVPN] Error: failed to generate UUID" >&2
    exit 1
fi

if ! grep -q "PLACEHOLDER_UUID" "$CONFIG"; then
    echo "[NikVPN] Error: PLACEHOLDER_UUID not found in ${CONFIG}" >&2
    exit 1
fi

sed -i "s/PLACEHOLDER_UUID/${UUID}/" "$CONFIG"

if grep -q "PLACEHOLDER_UUID" "$CONFIG"; then
    echo "[NikVPN] Error: failed to substitute UUID in ${CONFIG}" >&2
    exit 1
fi

echo "[NikVPN] Setup complete. Xray ${LATEST} installed with UUID: ${UUID}"
