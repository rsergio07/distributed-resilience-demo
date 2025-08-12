# RUNBOOK_FAILOVER.md – Blue/Green Resilience with HPA + Auto-Failover

This runbook demonstrates how a Kubernetes workload can self-heal, scale under load, and recover from a simulated outage — all without human intervention.  
We will use two identical deployments: **blue** and **green**. Traffic is sent to blue initially, but we’ll simulate failures and let our auto-failover watcher re-route traffic to green.

---

## Step-by-Step Execution

### Terminal A – Deploy the Offline Demo

```bash
./scripts/cleanup.sh --cluster
IMAGE_TAG=resilience-demo:1.1 ./scripts/deploy-offline.sh
```

**Purpose:**  
Cleans up any existing cluster state and redeploys the app using the pre-built local image (`resilience-demo:1.1`).

**Expected Result:**

- Namespace `distributed-resilience` is created  
- Two deployments (`web-blue`, `web-green`) and their HPAs are deployed  
- Service `web` initially points to the blue version

---

### Terminal B – Watch Pods

```bash
kubectl -n distributed-resilience get pods -w
```

**Purpose:**  
Continuously observe pods for both blue and green deployments.

**Expected Result:**

- 1 running pod for `web-blue`  
- 1 running pod for `web-green`  
- Pod restarts or scaling events will appear in real time

---

### Terminal C – Monitor HPA and Metrics

```bash
kubectl -n distributed-resilience get hpa -w
kubectl -n distributed-resilience top pods
```

**Purpose:**

- `get hpa -w` shows target CPU percentages and replica changes  
- `top pods` shows actual CPU usage

**Expected Result:**  
CPU% will stay low until load is generated. HPA will then scale replicas up or down accordingly.

---

### Terminal D – Auto-Failover Watcher

```bash
./scripts/failover-watcher.sh
```

**Purpose:**  
Monitors pod readiness and automatically switches the `web` Service between blue and green if the active version becomes unhealthy.

**Expected Result:**  
Initially, it will show:

```
[watcher] blue_ready=1 green_ready=1 svc=blue
```

When blue fails, it switches to:

```
[watcher] switching Service to GREEN
```

---

### Terminal A – Trigger HPA (Optional)

```bash
kubectl -n distributed-resilience patch svc web -p '{"spec":{"selector":{"app":"web","version":"green"}}}'
./scripts/load-test.sh 240 300 800
```

**Purpose:**  
Send heavy load to the green deployment so the HPA scales it out.

**Expected Result:**

- In Terminal B: green pods increase from 1 to ~5 replicas  
- In Terminal C: CPU% spikes, then replicas scale back down after load stops

---

### Terminal A – Simulate Failure

```bash
./scripts/simulate-failure.sh blue --outage 20
```

**Purpose:**  
Forcefully deletes all blue pods and delays their recovery by 20 seconds.

**Expected Result:**

- In Terminal B: blue pods terminate and disappear  
- In Terminal D: watcher detects outage and switches traffic to green  
- Browser shows green version  
- After recovery, watcher switches traffic back to blue

---

## Key Learning Points

- Blue/Green patterns isolate production traffic during failures  
- HPA automatically scales workloads under CPU load  
- Custom failover logic can redirect traffic without manual intervention

---