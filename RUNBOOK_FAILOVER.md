# Blue/Green Resilience with HPA + Auto-Failover

This runbook demonstrates **production-grade resilience patterns** in action. You'll watch a Kubernetes workload automatically self-heal, intelligently scale under load, and seamlessly recover from catastrophic failures—all without human intervention.

We're using **two identical deployments** (blue and green) with intelligent traffic routing. When things go wrong, our custom failover watcher instantly redirects traffic to the healthy deployment. This is how modern distributed systems achieve true resilience.

---

## Step 1 – Start with a Clean Slate

> **What I'm doing**: "First, let's ensure we have a completely clean environment. In production, you'd never do this, but for our demo, we want to start from a known good state."

```bash
./scripts/cleanup.sh --cluster
```

**What this command does:**
- Completely destroys the existing Minikube cluster (nuclear option!)
- Removes all pods, services, namespaces, and configurations
- Frees up system resources and Docker images
- Creates a fresh Kubernetes cluster from scratch

> **Speaker Note**: "This takes about 60-90 seconds. While we wait, let me explain what we're about to build..."

**Expected terminal output:**
```
Deleting Minikube cluster...
Cluster deleted successfully
Starting fresh Minikube cluster...
Minikube is ready!
```

---

### Deploy Our Resilience Demo

> **What I'm doing**: "Now we're deploying our complete resilience stack. I'm using offline mode because conference WiFi is... well, you know how conference WiFi is."

**Offline Mode (recommended for live demos)**
```bash
./scripts/deploy-offline.sh
```

**What happens behind the scenes:**
- Loads pre-built `resilience-demo:1.1` image from local cache
- No internet required—perfect for live demos
- Deploys both blue and green versions simultaneously
- Sets up Horizontal Pod Autoscalers for both deployments
- Configures service routing (initially pointing to blue)

> > **Pause Point**: "Notice we're deploying TWO identical versions. This isn't waste—it's insurance. Blue handles production traffic while green stands ready as our failover target."

**Expected result after deployment:**
```
Namespace 'distributed-resilience' created
Blue deployment: 1/1 pods running
Green deployment: 1/1 pods running
HPAs configured for auto-scaling
Service routing traffic to BLUE
Demo ready at http://192.168.49.2:30080
```

---

## Step 2 – Open Your Observation Windows

> **What I'm doing**: "Let's set up our monitoring. In production, you'd have fancy dashboards, but kubectl gives us everything we need to understand what's happening."

**Terminal Window 1: Watch Pods in Real-Time**
```bash
kubectl -n distributed-resilience get pods -w
```

**What you'll see:**
```
NAME                        READY   STATUS    RESTARTS   AGE
web-blue-7d4b8c8f9d-xyz12   1/1     Running   0          45s
web-green-6c9d7e5a4b-abc34  1/1     Running   0          45s
```

> **Speaker Note**: "The `-w` flag means 'watch'—any changes to pod status will appear immediately. Keep this window visible during the demo."

---

## Step 3 – Monitor the Auto-Scalers

**Terminal Window 2: Watch HPA Scaling Decisions**
```bash
kubectl -n distributed-resilience get hpa -w
```

**What this shows you:**
```
NAME        REFERENCE           TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
web-blue    Deployment/web-blue   2%/50%      1         5         1       1m
web-green   Deployment/web-green  1%/50%      1         5         1       1m
```

> > **What I'm explaining**: "See those TARGETS? That's current CPU usage versus our 50% threshold. When CPU hits 50%, the HPA will automatically add more pods. Right now we're barely using any CPU, so we stay at 1 replica."

---

## Step 4 – Check Current Resource Usage

**Terminal Window 3: Live CPU Monitoring**
```bash
watch -n 2 'kubectl -n distributed-resilience top pods'
```

**Current resource consumption:**
```
NAME                         CPU(cores)   MEMORY(bytes)   
web-blue-7d4b8c8f9d-xyz12    2m           64Mi
web-green-6c9d7e5a4b-abc34   2m           62Mi
```

> > **What this means**: "2 milicores is basically idle. Our apps are just sitting there waiting for traffic. But watch what happens when we put them under load..."

---

## Step 5 – Start Our Intelligent Failover System

> **What I'm doing**: "This is where it gets interesting. I'm starting our custom failover watcher—this is the brain that makes our system truly resilient."

**Terminal Window 4: Auto-Failover Watcher**
```bash
./scripts/failover-watcher.sh
```

**What you'll see initially:**
```
[2025-08-14 10:30:15] Starting failover watcher...
[watcher] blue_ready=1/1 green_ready=1/1 current_service=blue
[watcher] System healthy - no action needed
[watcher] blue_ready=1/1 green_ready=1/1 current_service=blue
```

> > **Pause Point**: "This watcher is constantly monitoring both deployments. Every 5 seconds, it checks: Are the pods healthy? Is the current service target working? If not, it automatically switches traffic to the healthy deployment."

**What the watcher does:**
- Monitors pod readiness for both blue and green deployments
- Tracks which deployment is currently receiving traffic
- Automatically switches the service selector when failures are detected
- Provides real-time logging of all decisions

---

## Step 6 – Demonstrate Auto-Scaling Under Load

> **What I'm doing**: "Let's see how our system handles a traffic spike. I'm going to hammer it with requests and watch it automatically scale up."

**Generate Heavy Load**
```bash
./scripts/load-test.sh 240 300 800
```

**Command breakdown:**
- `240` = Run for 240 seconds (4 minutes)
- `300` = 300 concurrent requests
- `800` = 800 requests per second

> **Speaker Note**: "In production, this might be Black Friday traffic or a viral social media post. Watch the magic happen..."

**What you'll observe:**

**In the HPA window:**
```
NAME        REFERENCE           TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
web-blue    Deployment/web-blue   89%/50%      1         5         1       3m
web-blue    Deployment/web-blue   89%/50%      1         5         3       3m
web-blue    Deployment/web-blue   67%/50%      1         5         4       4m
web-blue    Deployment/web-blue   45%/50%      1         5         5       5m
```

**In the pods window:**
```
web-blue-7d4b8c8f9d-xyz12   1/1     Running   0          3m
web-blue-7d4b8c8f9d-new01   0/1     Pending   0          0s
web-blue-7d4b8c8f9d-new01   1/1     Running   0          15s
web-blue-7d4b8c8f9d-new02   0/1     Pending   0          0s
web-blue-7d4b8c8f9d-new02   1/1     Running   0          12s
```

> **What I'm explaining**: "See how the system automatically detected high CPU usage and scaled from 1 pod to 5 pods? Each new pod takes about 15 seconds to start and join the load balancing pool. After the load stops, it will automatically scale back down."

---

## Step 7 – Simulate a Production Outage

> **What I'm doing**: "Now for the real test. What happens when our entire blue deployment fails catastrophically? Let's simulate a database crash, bad deployment, or infrastructure failure."

**Trigger Complete Blue Deployment Failure**
```bash
./scripts/simulate-failure.sh blue --outage 20
```

**What this command does:**
- Immediately deletes ALL blue pods (simulating total failure)
- Prevents blue deployment from recovering for 20 seconds
- Mimics real-world scenarios like corrupted container images or dependency failures

**Watch the failover in action:**

**Pods window shows:**
```
web-blue-7d4b8c8f9d-xyz12   1/1     Terminating   0          5m
web-blue-7d4b8c8f9d-new01   1/1     Terminating   0          2m
web-blue-7d4b8c8f9d-new02   1/1     Terminating   0          2m
```

**Failover watcher detects the problem:**
```
[watcher] blue_ready=0/3 green_ready=1/1 current_service=blue
[watcher] BLUE deployment has failed! Switching to GREEN...
[watcher] Service selector updated to GREEN
[watcher] blue_ready=0/3 green_ready=1/1 current_service=green
```

> **Pause Point**: "Notice the timing—our watcher detected the failure and switched traffic in under 10 seconds. Your users never experienced downtime."

**Open your browser** to see the visual proof:
```
http://$(minikube ip):30080
```

You'll see the green version of the app serving traffic while blue recovers.

**After 20 seconds, blue recovers:**
```
[watcher] blue_ready=1/1 green_ready=1/1 current_service=green
[watcher] Both deployments healthy - maintaining current routing
```

---

## Step 8 – Explore the Cost Implications of Resilience

> **What I'm doing**: "We've seen how resilience works in practice. Now, let's look at the financial side. How do these patterns impact our cloud bill? Our `calc_costs.py` script helps us understand the trade-offs."

**Run the Cost Simulation Script**
```bash
python3 cost/calc_costs.py
```

**What this command does:**

  - Runs a Python script that calculates monthly infrastructure costs for various deployment scenarios.
  - Models different strategies, including:
      - A single, always-on deployment (minimal cost, low resilience).
      - An always-on blue/green dual deployment (higher cost, high resilience).
      - Autoscaling to a higher number of pods during peak hours.
      - Scaling down to zero pods during off-hours to save money.
  - Presents a comparison report, showing potential savings or increased costs relative to a baseline.

> > **What I'm explaining**: "The report shows that while an 'always-on blue+green' strategy gives you maximum resilience, it also has a higher baseline cost. However, intelligent autoscaling and strategies like 'scale-to-zero' during idle periods can significantly optimize expenses without sacrificing reliability where it matters."

**Expected terminal output (example):**

```bash
=== Cost Simulation Report ===
Assumptions:
  vCPU price: $0.12/vCPU-hour
  Pod CPU request: 100m
  Hours/month: 730
  Peak hours/day: 2, Off-hours/day: 8
  Baseline scenario: Always-on blue+green (2 pods)

Scenario                                      Monthly Cost    Savings vs Baseline
------------------------------------------------------------------------------------
Always-on blue (1 pod)                             $8.76         +50.0%
Always-on blue+green (2 pods)                     $17.52           +0.0%
Peak 5 pods for 2h/day + 1 pod rest               $12.26         +30.0%
Scale-to-zero off-hours (8h/day off)               $6.57         +62.5%
```

---

## Key Learning Points

### Pattern 1: Blue/Green Deployment Strategy
- **Two identical environments** eliminate single points of failure
- **Instant traffic switching** provides zero-downtime deployments and failover
- **Independent scaling** allows each environment to handle different load profiles

### Pattern 2: Horizontal Pod Autoscaling
- **CPU-based scaling** automatically adjusts capacity to meet demand
- **Configurable thresholds** (50% CPU) balance performance and cost
- **Automatic scale-down** prevents resource waste when load decreases

### Pattern 3: Custom Failover Logic
- **Health monitoring** goes beyond basic readiness probes
- **Intelligent decision making** handles complex failure scenarios
- **Automated recovery** reduces mean time to recovery (MTTR) from minutes to seconds

### Production Implications
- **Cost efficiency**: Only scale when needed, automatically scale down
- **Reliability**: Multiple failure recovery mechanisms
- **Observability**: Real-time visibility into system health and decisions
- **Zero human intervention**: System self-heals without waking up engineers

---

## What We Just Accomplished

In less than 10 minutes, we built and demonstrated a production-grade resilient system that:

1. **Automatically scales** under load without human intervention
2. **Detects failures** in real-time using custom monitoring logic  
3. **Switches traffic instantly** when problems are detected
4. **Recovers gracefully** once issues are resolved
5. **Maintains zero downtime** throughout the entire process

This is how modern distributed systems achieve **true resilience**—not just handling expected failures, but gracefully adapting to the unexpected.
