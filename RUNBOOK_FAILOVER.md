# RUNBOOK_FAILOVER.md – Blue/Green Resilience with HPA + Auto-Failover

This runbook demonstrates how a Kubernetes workload can self-heal, scale under load, and recover from a simulated outage without human intervention.  
Two identical deployments — **blue** and **green** — are used. Traffic starts on blue, and failures trigger the auto-failover watcher to re-route traffic to green.

---

## Step 1 – Cleanup & Fresh Deployment

Before running, start with a clean Kubernetes environment to ensure all pods, services, and configurations are in a known good state.

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
./scripts/deploy-offline.sh
```

Behind the scenes:
- Uses the prebuilt resilience-demo:1.1 image from local Docker cache or TAR file.
- Preloads images into Minikube without external pulls.
- Deploys blue/green workloads, HPAs, and service routing.

---

**Option B – Online Mode**  
Use if you have a stable internet connection.

```bash
./scripts/deploy.sh
```

Behind the scenes:
- Builds or pulls required images from remote registries.
- Loads them into Minikube's image cache.
- Deploys blue/green workloads, HPAs, and service routing.

---

Expected result after either option:
- Namespace distributed-resilience created.
- Deployments web-blue and web-green start with 1 pod each.
- HPAs deployed for both.
- Service initially routes traffic to blue.

---

## Step 2 – Watch Pods

```bash
kubectl -n distributed-resilience get pods -w
```

Purpose: Observe pod status for blue and green deployments in real time.  
Expected result:
- 1 running pod for web-blue.
- 1 running pod for web-green.
- Scaling or restarts appear live.

---

## Step 3 – Monitor HPA Status

```bash
kubectl -n distributed-resilience get hpa -w
```

Purpose: Monitor CPU targets and replica changes in real time.  
Expected result: Shows HPA scaling decisions as CPU thresholds are crossed.

---

## Step 4 – Monitor CPU Metrics

```bash
kubectl -n distributed-resilience top pods
```

Purpose: View real CPU usage across all pods (run in a separate terminal).  
Expected result: CPU% remains low until load is applied; shows actual resource consumption.

---

## Step 5 – Start Auto-Failover Watcher

```bash
./scripts/failover-watcher.sh
```

Purpose: Monitors pod readiness and switches web Service between blue and green if the active version fails.

Expected result:

```
[watcher] blue_ready=1 green_ready=1 svc=blue
```

If blue fails:

```
[watcher] switching Service to GREEN
```

---

## Step 6 – Trigger HPA (Optional)

```bash
kubectl -n distributed-resilience patch svc web -p '{"spec":{"selector":{"app":"web","version":"green"}}}'
./scripts/load-test.sh 240 300 800
```

Purpose: Generate heavy load on green to trigger HPA scaling.  
Expected result:
- Green pods increase from 1 to ~5.
- CPU% spikes; scales back down after load stops.

---

## Step 7 – Simulate Failure

```bash
./scripts/simulate-failure.sh blue --outage 20
```

Purpose: Deletes all blue pods and delays recovery by 20 seconds.  
Expected result:
- Blue pods terminate.
- Watcher switches service to green.
- Browser shows green version.
- After recovery, watcher switches traffic back to blue.

---

## Key Learning Points

- Blue/Green patterns isolate production traffic during failures.
- HPA automatically scales workloads under CPU load.
- Custom failover logic enables traffic redirection without manual intervention.
