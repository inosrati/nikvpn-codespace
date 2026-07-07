#!/bin/bash
set -euo pipefail

CONFIG="/etc/xray/config.json"
XRAY_LOG="/tmp/xray.log"

if ! command -v xray >/dev/null 2>&1; then
    echo "[NikVPN] Error: xray binary not found. Did setup.sh run?" >&2
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "[NikVPN] Error: config not found at ${CONFIG}" >&2
    exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
    echo "[NikVPN] Error: tmux not found" >&2
    exit 1
fi

tmux kill-session -t nikvpn 2>/dev/null || true
tmux new-session -d -s nikvpn
tmux send-keys -t nikvpn "sudo /usr/local/bin/xray run -c ${CONFIG} &>${XRAY_LOG}" Enter

sleep 2

# Verify xray actually started; the command runs inside tmux so its exit status
# is not visible here. Fall back to inspecting the log for a running process.
if ! pgrep -x xray >/dev/null 2>&1; then
    echo "[NikVPN] Error: xray failed to start. Recent log output:" >&2
    tail -n 20 "$XRAY_LOG" >&2 2>/dev/null || echo "[NikVPN] (no log available at ${XRAY_LOG})" >&2
    exit 1
fi

# Resolve show-link.sh whether or not it is on PATH.
if command -v show-link.sh >/dev/null 2>&1; then
    show-link.sh
elif [ -x /usr/local/bin/show-link.sh ]; then
    /usr/local/bin/show-link.sh
else
    echo "[NikVPN] Warning: show-link.sh not found; run it manually to get your link" >&2
fi

tmux new-window -t nikvpn -n keepalive
tmux send-keys -t nikvpn:keepalive "while true; do curl -s --max-time 5 https://github.com/ -o /dev/null; sleep 180; done" Enter

echo "[NikVPN] Xray is running in background (tmux session: nikvpn)"
echo "[NikVPN] View logs: tmux attach -t nikvpn"
