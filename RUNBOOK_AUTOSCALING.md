# RUNBOOK_AUTOSCALING.md – Agentic AI-Driven Scaling for Blue Deployment

This runbook focuses on intelligent, non-HPA scaling driven by a Python “agent” process.  
In this setup, **green** is controlled by Kubernetes HPA, while **blue** is scaled dynamically by our AI mock agent based on CPU thresholds.

---

## Step-by-Step Execution

### Terminal A – Prep Environment

```bash
kubectl -n distributed-resilience delete hpa hpa-web-blue || true
kubectl -n distributed-resilience patch svc web -p '{"spec":{"selector":{"app":"web","version":"blue"}}}'
```

**Purpose:**  
Remove HPA from blue so our agent has full control, and ensure the `web` Service points to blue.

**Expected Result:**  
Blue stays at 1 replica until the agent changes it.

---

### Terminal B – Watch Pods

```bash
kubectl -n distributed-resilience get pods -w
```

**Purpose:**  
Track pod scaling events in real time.

**Expected Result:**  
Initially 1 blue pod, 1 green pod.

---

### Terminal C – Monitor CPU Metrics

```bash
kubectl -n distributed-resilience top pods
```

**Purpose:**  
See live CPU usage; scaling decisions will be based on this data.

**Expected Result:**  
CPU% remains low until intentional load is generated.

---

### Terminal D – Start the Agent

```bash
DEPLOYMENT=web-blue HIGH_M=90 LOW_M=30 UP_REPLICAS=5 DOWN_REPL=1 \
python3 agents/agentic_ai_mock.py
```

**Purpose:**  
Run the scaling agent with the following parameters:

- `HIGH_M=90` → scale up if CPU > 90%  
- `LOW_M=30` → scale down if CPU < 30%  
- `UP_REPLICAS=5` → max scale out to 5 replicas  
- `DOWN_REPL=1` → scale down to 1 replica

**Expected Result:**  
Terminal D logs scaling actions when thresholds are crossed.

---

### Terminal E – Burn CPU in Blue Pods

```bash
./scripts/burn-cpu-blue.sh 150
```

**Purpose:**  
Generate sustained CPU load for 150 seconds on blue pods.

**Expected Result:**

- In Terminal C: CPU% climbs above 90%  
- In Terminal D: agent logs scaling from 1 → 5 replicas  
- After load ends: CPU% drops and agent scales down to 1 replica

---

### Terminal F – (Optional) Combine with Failover Watcher

```bash
./scripts/failover-watcher.sh
./scripts/simulate-failure.sh blue --outage 20
```

**Purpose:**  
Demonstrate that the agent’s scaling control for blue works in combination with the automatic failover system.

**Expected Result:**

- Service switches to green during blue outage  
- Service switches back to blue after recovery

---

## Key Learning Points

- HPA is not the only scaling strategy — custom agents allow for more complex logic  
- AI-driven decision-making enables scaling based on multiple signals, not just CPU  
- Manual failover scripts can coexist with automated scaling logic

---