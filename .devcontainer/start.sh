#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/common.sh" ]; then
    . "$SCRIPT_DIR/common.sh"
else
    . /usr/local/bin/common.sh
fi

tmux kill-session -t nikvpn 2>/dev/null || true
tmux new-session -d -s nikvpn
tmux send-keys -t nikvpn "sudo /usr/local/bin/xray run -c ${XRAY_CONFIG} &>/tmp/xray.log" Enter
sleep 2
show-link.sh
tmux new-window -t nikvpn -n keepalive
tmux send-keys -t nikvpn:keepalive "while true; do curl -s --max-time 5 https://github.com/ -o /dev/null; sleep 180; done" Enter
log "Xray is running in background (tmux session: nikvpn)"
log "View logs: tmux attach -t nikvpn"
