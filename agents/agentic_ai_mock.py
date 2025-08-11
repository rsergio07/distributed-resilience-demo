#!/usr/bin/env python3
"""
Agentic AI (mock) for Kubernetes:
- Observes CPU via `kubectl top pods`
- Decides: scale up/down (thresholds)
- Acts: kubectl scale on the selected Deployment

This is intentionally simple (no cloud calls) so it's demo-safe and offline-ready.
"""

import subprocess
import time
import os
from statistics import mean

NAMESPACE   = os.getenv("NAMESPACE", "distributed-resilience")
DEPLOYMENT  = os.getenv("DEPLOYMENT", "web-blue")  # start with blue; switch to green if you want
HIGH_M      = int(os.getenv("HIGH_M", "120"))      # mCPU threshold to scale up
LOW_M       = int(os.getenv("LOW_M", "40"))        # mCPU threshold to scale down
UP_REPLICAS = int(os.getenv("UP_REPLICAS", "5"))
DOWN_REPL   = int(os.getenv("DOWN_REPL", "1"))
INTERVAL_S  = int(os.getenv("INTERVAL_S", "10"))

def kubectl(*args) -> subprocess.CompletedProcess:
    return subprocess.run(["kubectl", "-n", NAMESPACE, *args], text=True, capture_output=True)

def get_avg_cpu_milli() -> int:
    # Requires metrics-server; ensure it's enabled and warmed up
    res = kubectl("top", "pods", "--no-headers")
    if res.returncode != 0 or not res.stdout.strip():
        return 0
    mcpu = []
    for line in res.stdout.strip().splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        # CPU column like "37m"
        try:
            mcpu.append(int(parts[1].rstrip("m")))
        except ValueError:
            pass
    return int(mean(mcpu)) if mcpu else 0

def scale_to(replicas: int):
    print(f"[AI-Agent] -> scaling {DEPLOYMENT} to replicas={replicas}")
    res = kubectl("scale", "deployment", DEPLOYMENT, f"--replicas={replicas}")
    if res.returncode != 0:
        print(f"[AI-Agent] scale error: {res.stderr.strip()}")

def main():
    print(f"[AI-Agent] Watching namespace={NAMESPACE}, deployment={DEPLOYMENT}")
    print(f"[AI-Agent] Thresholds: HIGH>{HIGH_M}m → {UP_REPLICAS} replicas, LOW<{LOW_M}m → {DOWN_REPL} replica(s)")
    while True:
        avg = get_avg_cpu_milli()
        print(f"[AI-Agent] Avg CPU: {avg}m")
        if avg > HIGH_M:
            scale_to(UP_REPLICAS)
        elif avg < LOW_M:
            scale_to(DOWN_REPL)
        time.sleep(INTERVAL_S)

if __name__ == "__main__":
    main()
