
#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="distributed-resilience"

URL="$(minikube service web -n "$NAMESPACE" --url | head -n1)"
echo "[+] Sending load to: $URL"
echo "[i] Press Ctrl+C to stop"
while true; do
  curl -s -o /dev/null "$URL" &
  sleep 0.05
done
