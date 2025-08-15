#!/usr/bin/env python3
import subprocess
import random
import time
from datetime import datetime

# Settings
MAX_REPLICAS = 5
MIN_REPLICAS = 1
NAMESPACE = "distributed-resilience"
DEPLOYMENT = "web-blue"
BUSINESS_HOURS = (8, 18)  # 08:00 to 18:00 local time
LOG_FILE = "agentic_ai_decisions.log"

# Mock cost data
COST_PER_REPLICA_PER_HOUR = 0.05  # USD (example)

def log_decision(message):
    """Append decisions and events to a log file with timestamps."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(LOG_FILE, "a") as log:
        log.write(entry + "\n")

def get_current_replicas():
    try:
        result = subprocess.run(
            ["kubectl", "get", "deployment", DEPLOYMENT, "-n", NAMESPACE, "-o", "jsonpath={.spec.replicas}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        log_decision(f"[ERROR] Could not get current replicas: {e.stderr.strip()}")
        return None

def scale_replicas(count):
    try:
        subprocess.run(
            ["kubectl", "scale", f"deployment/{DEPLOYMENT}", f"--replicas={count}", "-n", NAMESPACE],
            check=True
        )
        log_decision(f"[ACTION] Scaled to {count} replicas. Estimated hourly cost: ${count * COST_PER_REPLICA_PER_HOUR:.2f}")
    except subprocess.CalledProcessError as e:
        log_decision(f"[ERROR] Could not scale deployment: {e.stderr.strip()}")

def simulate_cpu_trend():
    """
    Simulates CPU usage percentage.
    Trend: slight increase or decrease over time.
    """
    return random.randint(40, 95)

def main():
    log_decision(f"[START] Agentic AI Mock started for deployment '{DEPLOYMENT}' in namespace '{NAMESPACE}'")
    log_decision(f"[INFO] Business hours: {BUSINESS_HOURS[0]:02d}:00 to {BUSINESS_HOURS[1]:02d}:00")
    log_decision(f"[INFO] Max replicas: {MAX_REPLICAS}, Min replicas: {MIN_REPLICAS}")
    log_decision("------------------------------------------------------")

    while True:
        # Local time check
        now = datetime.now()
        if now.hour < BUSINESS_HOURS[0] or now.hour >= BUSINESS_HOURS[1]:
            log_decision(f"[INFO] Outside business hours ({now.strftime('%H:%M')}). No scaling action.")
            time.sleep(60)
            continue

        # Get current state
        current_replicas = get_current_replicas()
        if current_replicas is None:
            time.sleep(60)
            continue

        # Simulate CPU usage
        cpu_usage = simulate_cpu_trend()
        log_decision(f"[METRIC] Simulated CPU usage: {cpu_usage}% | Current replicas: {current_replicas}")

        # Scaling logic
        if cpu_usage > 80 and current_replicas < MAX_REPLICAS:
            new_replicas = current_replicas + 1
            log_decision(f"[DECISION] High CPU detected. Gradually scaling up to {new_replicas} replicas.")
            scale_replicas(new_replicas)

        elif cpu_usage < 50 and current_replicas > MIN_REPLICAS:
            new_replicas = current_replicas - 1
            log_decision(f"[DECISION] Low CPU detected. Scaling down to {new_replicas} replicas to save cost.")
            scale_replicas(new_replicas)

        else:
            log_decision("[DECISION] No scaling change needed.")

        # Wait before next check
        time.sleep(60)

if __name__ == "__main__":
    main()
