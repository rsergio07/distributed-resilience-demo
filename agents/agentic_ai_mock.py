#!/usr/bin/env python3
"""
Agentic AI (mock) for Kubernetes:
- Observes CPU via `kubectl top pods`
- Decides with hysteresis: HIGH -> scale up, LOW -> scale down
- Acts only when desired != current replicas
- Cooldown between actions to avoid flapping
"""

import subprocess, time, os
from statistics import mean

NS         = os.getenv("NAMESPACE", "distributed-resilience")
DEPLOY     = os.getenv("DEPLOYMENT", "web-blue")   # set to web-green if you want
HIGH_M     = int(os.getenv("HIGH_M", "120"))       # scale up if avg CPU > HIGH_M (mCPU)
LOW_M      = int(os.getenv("LOW_M", "40"))         # scale down if avg CPU < LOW_M
UP_REPL    = int(os.getenv("UP_REPLICAS", "5"))
DOWN_REPL  = int(os.getenv("DOWN_REPL", "1"))
INTERVAL_S = int(os.getenv("INTERVAL_S", "10"))
COOLDOWN_S = int(os.getenv("COOLDOWN_S", "30"))    # minimum seconds between actions

last_action_at = 0

def k(*args):
    return subprocess.run(["kubectl", "-n", NS, *args], text=True,
                          capture_output=True)

def get_avg_cpu_m():
    r = k("top", "pods", "--no-headers")
    if r.returncode != 0 or not r.stdout.strip():
        return 0
    vals = []
    for line in r.stdout.strip().splitlines():
        cols = line.split()
        if len(cols) >= 2 and cols[1].endswith("m"):
            try:
                vals.append(int(cols[1][:-1]))
            except ValueError:
                pass
    return int(mean(vals)) if vals else 0

def get_current_replicas():
    r = k("get", "deploy", DEPLOY, "-o", "jsonpath={.spec.replicas}")
    return int(r.stdout or 0)

def scale_to(n):
    global last_action_at
    now = time.time()
    if now - last_action_at < COOLDOWN_S:
        print(f"[AI-Agent] Cooldown active ({int(COOLDOWN_S - (now - last_action_at))}s left), skip action.")
        return
    cur = get_current_replicas()
    if cur == n:
        print(f"[AI-Agent] Desired replicas={n} equals current={cur}; no action.")
        return
    print(f"[AI-Agent] Scaling {DEPLOY} from {cur} -> {n}")
    r = k("scale", "deployment", DEPLOY, f"--replicas={n}")
    if r.returncode != 0:
        print(f"[AI-Agent] scale error: {r.stderr.strip()}")
    else:
        last_action_at = now

def main():
    print(f"[AI-Agent] Watching ns={NS}, deploy={DEPLOY}")
    print(f"[AI-Agent] Thresholds: HIGH>{HIGH_M}m -> {UP_REPL} | LOW<{LOW_M}m -> {DOWN_REPL}")
    while True:
        avg = get_avg_cpu_m()
        print(f"[AI-Agent] Avg CPU: {avg}m")
        if avg > HIGH_M:
            scale_to(UP_REPL)
        elif avg < LOW_M:
            scale_to(DOWN_REPL)
        else:
            print("[AI-Agent] Within band; hold steady.")
        time.sleep(INTERVAL_S)

if __name__ == "__main__":
    main()