#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="distributed-resilience"

URL="$(minikube service web -n "$NAMESPACE" --url | head -n1)"
echo "[+] Sending CPU-intensive load to: $URL/work?ms=200"
echo "[i] Press Ctrl+C to stop"

# naive concurrent load without extra tools
while true; do
  for i in {1..50}; do
    curl -s -o /dev/null "$URL/work?ms=200" &
  done
  sleep 0.1
done
