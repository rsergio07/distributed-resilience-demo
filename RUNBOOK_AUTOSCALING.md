# RUNBOOK_AUTOSCALING.md – Agentic AI-Driven Scaling for Blue Deployment

This runbook focuses on intelligent, non-HPA scaling driven by a Python "agent" process.  
In this setup, **green** is controlled by Kubernetes HPA, while **blue** is scaled dynamically by our AI mock agent based on CPU thresholds.

---

## Step 1 – Cleanup & Fresh Deployment

Before running this demo, start with a clean Kubernetes environment and deploy the workloads.  
This ensures all pods, services, and configurations are in a known good state.

```bash
./scripts/cleanup.sh --cluster
```

What this does:
- Deletes the entire Minikube cluster (hard reset).
- Removes all workloads, namespaces, and configurations.
- Frees up system resources.

---

### Deploying the Demo

**Option A – Offline Mode (recommended for live demos)**  
Use if you have already preloaded all required images locally.

```bash
IMAGE_TAG=resilience-demo:1.1 ./scripts/deploy-offline.sh
```

Behind the scenes:
- Uses the prebuilt resilience-demo:1.1 image from local Docker cache or TAR file.
- Preloads all images into Minikube.
- Deploys blue/green workloads, HPAs, and service routing.

---

**Option B – Online Mode**  
Use if you have a stable internet connection.

```bash
./scripts/deploy.sh
```

Behind the scenes:
- Builds or pulls images from remote registries.
- Loads them into Minikube's cache.
- Deploys blue/green workloads, HPAs, and service routing.

---

Expected result after either option:
- Namespace distributed-resilience created.
- Two deployments (web-blue, web-green) each start with 1 pod.
- HPAs deployed for both.
- Service routes traffic to blue initially.

---

## Step 2 – Prep Environment

```bash
kubectl -n distributed-resilience delete hpa hpa-web-blue || true
kubectl -n distributed-resilience patch svc web -p '{"spec":{"selector":{"app":"web","version":"blue"}}}'
```

Purpose:
- Remove HPA from blue so the agent has full control.
- Ensure the web Service points to blue.

Expected result:
- Blue stays at 1 replica until the agent changes it.

---

## Step 3 – Watch Pods

```bash
kubectl -n distributed-resilience get pods -w
```

Purpose: Track pod scaling events in real time.  
Expected result: Initially 1 blue pod, 1 green pod.

---

## Step 4 – Monitor CPU Metrics

```bash
kubectl -n distributed-resilience top pods
```

Purpose: View live CPU usage.  
Expected result: CPU% remains low until intentional load is generated.

---

## Step 5 – Start the Agent

```bash
DEPLOYMENT=web-blue HIGH_M=90 LOW_M=30 UP_REPLICAS=5 DOWN_REPL=1 \
python3 agents/agentic_ai_mock.py
```

Purpose: Run the scaling agent with parameters:
- HIGH_M=90 → scale up if CPU > 90%
- LOW_M=30 → scale down if CPU < 30%
- UP_REPLICAS=5 → max scale out to 5 replicas
- DOWN_REPL=1 → scale down to 1 replica

Expected result: Agent logs scaling actions when thresholds are crossed.

---

## Step 6 – Burn CPU in Blue Pods

```bash
./scripts/burn-cpu-blue.sh 150
```

Purpose: Generate sustained CPU load for 150 seconds on blue pods.  
Expected result:
- CPU% climbs above 90% in metrics output.
- Agent scales from 1 → 5 replicas.
- After load ends, agent scales down to 1 replica.

---

## Step 7 – Start Failover Watcher

```bash
./scripts/failover-watcher.sh
```

Purpose: Start monitoring for deployment failures and automatic service switching.  
Expected result: Watcher begins monitoring blue deployment health and prepares to handle failover events.

---

## Step 8 – Simulate Blue Deployment Failure

```bash
./scripts/simulate-failure.sh blue --outage 20
```

Purpose: Simulate a 20-second outage in the blue deployment to demonstrate agent scaling alongside automatic failover.  
Expected result:
- Service switches to green during blue outage.
- Service switches back to blue after recovery.

---

## Key Learning Points

- HPA is not the only scaling strategy — custom agents allow more complex logic.
- AI-driven decision-making enables scaling based on multiple signals.
- Manual failover scripts can coexist with automated scaling logic.