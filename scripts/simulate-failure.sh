
#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="distributed-resilience"
TARGET="${1:-blue}"  # blue|green

echo "[+] Simulating failure: deleting pods for version=$TARGET"
kubectl -n "$NAMESPACE" delete pod -l app=web,version="$TARGET" --grace-period=0 --force
echo "[i] Watch new pods come up (Ctrl+C to stop)"
kubectl -n "$NAMESPACE" get pods -l app=web -w
