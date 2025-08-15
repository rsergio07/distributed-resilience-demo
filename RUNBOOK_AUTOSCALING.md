# Agentic AI-Driven Scaling for Blue Deployment

This runbook demonstrates the **next generation of intelligent scaling** - moving beyond simple CPU thresholds to AI-driven decision making. Instead of relying solely on Kubernetes HPA, we'll deploy a custom Python agent that makes sophisticated scaling decisions based on multiple signals and business logic.

In this setup, **green deployment** uses traditional Kubernetes HPA scaling, while **blue deployment** is controlled by our intelligent AI agent. This side-by-side comparison shows the evolution from reactive scaling to predictive, context-aware operations.

-----

## Step 1 – Start with a Clean Slate

> **What I'm doing**: "Before we begin, we'll ensure our environment is completely clean. This prevents any old configurations or running pods from interfering with our new demonstration."

```bash
./scripts/cleanup.sh --cluster
```

**What this command does:**

  - Completely destroys the existing Minikube cluster.
  - Removes all pods, services, namespaces, and configurations.
  - Frees up system resources and Docker images.
  - Creates a fresh Kubernetes cluster from scratch.

**Expected terminal output:**

```
Deleting Minikube cluster...
Cluster deleted successfully
Starting fresh Minikube cluster...
Minikube is ready!
```

-----

## Step 2 – Deploy Our AI-Enhanced Demo

> **What I'm doing**: "Now that we have a clean environment, we'll deploy our resilient infrastructure. We're setting up a side-by-side comparison with traditional HPA on one deployment and our AI agent on the other."

**Offline Mode (recommended for live demos)**

```bash
./scripts/deploy-offline-agent.sh
```

**What happens behind the scenes:**

  - Loads pre-built `resilience-demo:1.1` image from local cache.
  - **Deploys both blue and green deployments, but only green gets a Horizontal Pod Autoscaler.**
  - Sets up service routing (initially pointing to blue).

> **Pause Point**: "Notice we're deploying with standard HPA for green but **no HPA for blue**. This sets the stage for our comparison of reactive versus intelligent scaling."

**Expected result after deployment:**

```
...
Namespace 'distributed-resilience' created
Blue deployment: 1/1 pods running
Green deployment: 1/1 pods running
HPA configured for green deployment only
Service routing traffic to BLUE
AI agent ready to deploy
```

-----

## Step 3 – Set Up Monitoring Windows

> **What I'm doing**: "Let's establish our monitoring setup so we can watch both traditional and AI-driven scaling in action."

**Terminal Window 1: Watch Pod Scaling in Real-Time**

```bash
kubectl -n distributed-resilience get pods -w
```

**What you'll see initially:**

```
NAME                        READY   STATUS    RESTARTS   AGE
web-blue-7d4b8c8f9d-xyz12   1/1     Running   0          2m
web-green-6c9d7e5a4b-abc34  1/1     Running   0          2m
```

-----

## Step 4 – Monitor Resource Consumption

**Terminal Window 2: Live CPU Monitoring**

```bash
watch -n 2 'kubectl -n distributed-resilience top pods'
```

**Current baseline readings:**

```
NAME                         CPU(cores)   MEMORY(bytes)   
web-blue-7d4b8c8f9d-xyz12    3m           58Mi
web-green-6c9d7e5a4b-abc34   2m           61Mi
```

> **What this shows**: "Both deployments are essentially idle right now. But our AI agent is watching these metrics continuously, ready to make intelligent scaling decisions based on trends, not just instant thresholds."

-----

## Step 5 – Deploy the AI Scaling Agent

> **What I'm doing**: "Here's where it gets interesting. I'm deploying our AI agent with specific parameters that demonstrate intelligent decision-making."

```bash
DEPLOYMENT=web-blue HIGH_M=90 LOW_M=30 UP_REPLICAS=5 DOWN_REPL=1 \
python3 agents/agentic_ai_mock.py
```

**Agent configuration explained:**

  - `DEPLOYMENT=web-blue` → Controls only the blue deployment
  - `HIGH_M=90` → Scale up when CPU exceeds 90% (more conservative than typical 50%)
  - `LOW_M=30` → Scale down when CPU drops below 30% (prevents thrashing)
  - `UP_REPLICAS=5` → Maximum scale-out to 5 replicas
  - `DOWN_REPL=1` → Scale down to minimum 1 replica

> **What makes this intelligent**: "Unlike HPA which reacts immediately to threshold breaches, this agent can implement sophisticated logic: trend analysis, cost considerations, business hours awareness, and predictive scaling."

**Expected agent output:**

```
[AI Agent] Starting intelligent scaling agent for web-blue
[AI Agent] Monitoring CPU trends and making intelligent scaling decisions.
[AI Agent] Thresholds: Scale-up >90%, Scale-down <30%
[AI Agent] Max replicas: 5, Min replicas: 1
------------------------------------------------------
[METRIC] Current CPU: 3% | Replicas: 1
[DECISION] Current state is optimal. No scaling needed.
```

-----

## Step 6 – Trigger AI-Driven Scaling

> **What I'm doing**: "Let's generate sustained load specifically on blue pods to watch our AI agent make scaling decisions."

```bash
./scripts/burn-cpu-blue.sh 150
```

**What this script does:**

  - Generates intensive CPU load for 150 seconds (2.5 minutes)
  - Targets only blue deployment pods
  - Creates realistic load patterns that trigger intelligent scaling

> **Speaker Note**: "This simulates a real production scenario - perhaps a batch job, traffic spike, or resource-intensive operation. Watch how our AI agent responds differently than traditional HPA would."

**What you'll observe:**

**In the CPU monitoring window:**

```
NAME                         CPU(cores)   MEMORY(bytes)   
web-blue-7d4b8c8f9d-xyz12    950m         58Mi
web-green-6c9d7e5a4b-abc34   2m           61Mi
```

**In the AI agent output:**

```
[METRIC] Current CPU: 95% | Replicas: 1
[DECISION] Waiting for sustained high CPU trend.
[METRIC] Current CPU: 92% | Replicas: 1
[DECISION] Waiting for sustained high CPU trend.
[METRIC] Current CPU: 91% | Replicas: 1
[DECISION] Sustained high CPU trend detected. Gradually scaling up to 2.
[ACTION] Scaled to 2 replicas. Estimated hourly cost: $0.10
...
```

> **What I'm explaining**: "Notice the intelligent scaling pattern. Instead of immediately jumping to 5 replicas, the agent scales gradually, monitors the impact, then makes further decisions based on whether the additional capacity resolves the load."

**After load test completes:**

```
[METRIC] Current CPU: 25% | Replicas: 3
[DECISION] Waiting for sustained low CPU trend.
...
[DECISION] Sustained low CPU trend detected. Scaling down to 2 for cost optimization.
[ACTION] Scaled to 2 replicas. Estimated hourly cost: $0.10
```

-----

## Key Learning Points

### Evolution Beyond Traditional HPA

  - **Traditional HPA**: Reactive scaling based on single metrics (CPU/memory)
  - **AI-driven scaling**: Proactive decisions considering trends, cost, and business context
  - **Gradual scaling**: Intelligent agents can implement sophisticated scaling patterns

### Intelligent Decision Making

  - **Trend analysis**: Makes decisions based on sustained patterns, not instant spikes
  - **Cost awareness**: Balances performance needs with resource optimization
  - **Business logic**: Can incorporate custom rules like business hours, traffic patterns, or application-specific requirements

-----

## What We Just Accomplished

We demonstrated the **next generation of infrastructure automation** by building a system that:

1.  **Makes intelligent scaling decisions** using AI-driven logic instead of simple thresholds.
2.  **Optimizes for both performance and cost** through sophisticated decision-making algorithms.
3.  **Provides a foundation for custom business logic** in infrastructure operations.

This represents the evolution from reactive infrastructure to **predictive, intelligent operations** - the foundation of truly autonomous systems.