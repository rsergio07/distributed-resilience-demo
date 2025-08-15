import os
import time
import subprocess
import json
import re

# Constants
NAMESPACE = os.environ.get("NAMESPACE", "distributed-resilience")
DEPLOYMENT = os.environ.get("DEPLOYMENT", "web-blue")
HIGH_CPU_THRESHOLD_PERCENT = int(os.environ.get("HIGH_M", 90))
LOW_CPU_THRESHOLD_PERCENT = int(os.environ.get("LOW_M", 30))
MAX_REPLICAS = int(os.environ.get("UP_REPLICAS", 5))
MIN_REPLICAS = int(os.environ.get("DOWN_REPL", 1))

# Trend detection
CPU_TREND = []
TREND_LENGTH = 3  # Number of consecutive high/low readings to confirm a trend

# Cost calculation
HOURLY_COST_PER_REPLICA = 0.05
COST_LOG_FILE = "agentic_ai_decisions.log"

def log_with_timestamp(message):
    """Logs a message with a timestamp."""
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
    print(f"[{timestamp}] {message}")

def get_cpu_metrics(deployment_name):
    """
    Fetches the average CPU usage for a given deployment by its labels.
    Returns the average CPU percentage and the number of replicas.
    """
    try:
        # Get all pod names for the deployment using its labels
        pod_names_cmd = ["kubectl", "get", "pods", "-n", NAMESPACE, "-l", f"app=web,version={deployment_name.split('-')[-1]}", "-o", "jsonpath='{.items[*].metadata.name}'"]
        pod_names_output = subprocess.run(pod_names_cmd, capture_output=True, text=True, check=True).stdout.strip().strip("'")
        pod_names = pod_names_output.split() if pod_names_output else []

        if not pod_names:
            return 0, 0

        total_cpu = 0
        running_pods = 0
        
        # Check pod status to avoid errors on non-running pods
        pod_status_cmd = ["kubectl", "get", "pods", "-n", NAMESPACE, "-l", f"app=web,version={deployment_name.split('-')[-1]}", "-o", "json"]
        pod_status_output = subprocess.run(pod_status_cmd, capture_output=True, text=True, check=True).stdout
        pods_info = json.loads(pod_status_output)
        
        ready_pods = [p for p in pods_info['items'] if p['status']['phase'] == 'Running' and all(c['ready'] for c in p['status'].get('containerStatuses', []))]
        
        if not ready_pods:
            return 0, len(pod_names)

        for pod in ready_pods:
            pod_name = pod['metadata']['name']
            top_cmd = ["kubectl", "top", "pod", "-n", NAMESPACE, pod_name]
            top_output = subprocess.run(top_cmd, capture_output=True, text=True, check=True).stdout
            
            lines = top_output.strip().split('\n')
            if len(lines) > 1:
                parts = re.split(r'\s+', lines[1])
                cpu_core = parts[1]
                if cpu_core.endswith('m'):
                    cpu_milli = int(cpu_core[:-1])
                    total_cpu += cpu_milli
                    running_pods += 1

        if running_pods == 0:
            return 0, len(pod_names)
            
        # Assuming 1000m is 100% of a core
        average_cpu_percent = (total_cpu / running_pods) / 10
        return int(average_cpu_percent), len(pod_names)
    except Exception as e:
        log_with_timestamp(f"[ERROR] Could not get metrics: {e}")
        return 0, 0

def scale_deployment(replicas):
    """Scales the deployment to the specified number of replicas."""
    try:
        cmd = ["kubectl", "scale", "deployment", "-n", NAMESPACE, DEPLOYMENT, f"--replicas={replicas}"]
        subprocess.run(cmd, check=True)
        log_with_timestamp(f"[ACTION] Scaled to {replicas} replicas. Estimated hourly cost: ${replicas * HOURLY_COST_PER_REPLICA:.2f}")
    except Exception as e:
        log_with_timestamp(f"[ERROR] Could not scale deployment: {e}")

def make_scaling_decision(cpu_percent, replicas):
    """
    Decides whether to scale up or down based on current metrics and trends.
    This is where the "intelligent" logic resides.
    """
    # Simple moving average for trend detection
    CPU_TREND.append(cpu_percent)
    if len(CPU_TREND) > TREND_LENGTH:
        CPU_TREND.pop(0)

    # Scale up logic
    if cpu_percent > HIGH_CPU_THRESHOLD_PERCENT and replicas < MAX_REPLICAS:
        if all(c > HIGH_CPU_THRESHOLD_PERCENT for c in CPU_TREND):
            if replicas == 0:
                # Special case to go from 0 to MIN_REPLICAS
                log_with_timestamp("[DECISION] Sustained high CPU trend detected. Gradually scaling up.")
                new_replicas = replicas + 1
            else:
                log_with_timestamp("[DECISION] Sustained high CPU trend detected. Gradually scaling up.")
                # Only scale up by one replica at a time.
                new_replicas = replicas + 1
            scale_deployment(new_replicas)
            time.sleep(15)  # Add a delay to make the gradual effect visible.
        else:
            log_with_timestamp("[DECISION] High CPU spike detected, waiting for sustained trend.")
    
    # Scale down logic
    elif cpu_percent < LOW_CPU_THRESHOLD_PERCENT and replicas > MIN_REPLICAS:
        if all(c < LOW_CPU_THRESHOLD_PERCENT for c in CPU_TREND):
            log_with_timestamp("[DECISION] Sustained low CPU trend detected. Gradually scaling down.")
            # Only scale down by one replica at a time.
            new_replicas = replicas - 1
            scale_deployment(new_replicas)
            time.sleep(15) # Add a delay to make the gradual effect visible.
        else:
            log_with_timestamp("[DECISION] Low CPU detected, waiting for sustained trend.")
    
    else:
        log_with_timestamp("[DECISION] Current state is optimal. No scaling needed.")

def main():
    """Main loop for the agent."""
    log_with_timestamp(f"[START] Agentic AI started for deployment '{DEPLOYMENT}'")
    log_with_timestamp(f"[INFO] Monitoring CPU trends and making intelligent scaling decisions.")
    log_with_timestamp(f"[INFO] Thresholds: Scale-up >{HIGH_CPU_THRESHOLD_PERCENT}%, Scale-down <{LOW_CPU_THRESHOLD_PERCENT}%")
    log_with_timestamp(f"[INFO] Max replicas: {MAX_REPLICAS}, Min replicas: {MIN_REPLICAS}")
    log_with_timestamp("-" * 50)
    
    while True:
        cpu_percent, replicas = get_cpu_metrics(DEPLOYMENT)
        log_with_timestamp(f"[METRIC] Current CPU: {cpu_percent}% | Replicas: {replicas}")
        make_scaling_decision(cpu_percent, replicas)
        time.sleep(10)

if __name__ == "__main__":
    main()