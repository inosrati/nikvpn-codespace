#!/bin/bash
while true; do
  curl -s http://localhost:443 > /dev/null
  echo "[$(date)] Keepalive ping sent to NikVPN proxy"
  sleep 240
done
