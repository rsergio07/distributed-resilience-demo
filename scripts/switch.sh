
#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="distributed-resilience"
TARGET="${1:-green}"  # blue|green

if [[ "$TARGET" != "blue" && "$TARGET" != "green" ]]; then
  echo "Usage: $0 [blue|green]"
  exit 1
fi

echo "[+] Switching Service selector to version=$TARGET"
kubectl -n "$NAMESPACE" patch service web -p "$(cat <<EOF
{
  "spec": {
    "selector": {
      "app": "web",
      "version": "$TARGET"
    }
  }
}
EOF
)"
kubectl -n "$NAMESPACE" get svc web -o wide
