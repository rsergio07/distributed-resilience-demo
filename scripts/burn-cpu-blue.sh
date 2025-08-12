#!/usr/bin/env bash
set -euo pipefail
NS="distributed-resilience"
DUR="${1:-120}"   # seconds

# Run a CPU loop inside each blue pod (in background) for DUR seconds
PODS=$(kubectl -n "$NS" get pods -l app=web,version=blue -o name)
if [ -z "$PODS" ]; then
  echo "[x] No blue pods found."
  exit 1
fi

echo "[+] Burning CPU in blue pods for ${DUR}s ..."
for p in $PODS; do
  echo " -> $p"
  kubectl -n "$NS" exec "$p" -- sh -c "python - <<'PY' >/dev/null 2>&1 & 
import time, math, random
end=time.time()+$DUR
x=0.0
while time.time()<end:
    x += math.sqrt(random.random())
print(x)
PY" || true
done

echo "[i] CPU burn started (background). Check 'kubectl top pods'."