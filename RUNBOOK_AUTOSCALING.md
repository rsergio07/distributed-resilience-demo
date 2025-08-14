# RUNBOOK_AUTOSCALING.md – Agentic AI-Driven Scaling for Blue Deployment

This runbook demonstrates the **next generation of intelligent scaling** - moving beyond simple CPU thresholds to AI-driven decision making. Instead of relying solely on Kubernetes HPA, we'll deploy a custom Python agent that makes sophisticated scaling decisions based on multiple signals and business logic.

In this setup, **green deployment** uses traditional Kubernetes HPA scaling, while **blue deployment** is controlled by our intelligent AI agent. This side-by-side comparison shows the evolution from reactive scaling to predictive, context-aware operations.

---

## Step 1 – Start with a Clean Slate

> **What I'm doing**: "We're going to build on the previous demo, but this time we're exploring how AI agents can make smarter scaling decisions than traditional HPA. Let's start fresh to see the difference."

```bash
./scripts/cleanup.sh --cluster
```

**What this command does:**
- Completely destroys the existing Minikube cluster
- Removes all pods, services, namespaces, and configurations
- Frees up system resources and Docker images
- Creates a fresh Kubernetes cluster from scratch

**Speaker Note**: "While this rebuilds, let me explain what makes AI-driven scaling different. Traditional HPA only looks at CPU or memory. Our agent can consider business context, cost implications, and predictive patterns."

**Expected terminal output:**
```
Deleting Minikube cluster...
Cluster deleted successfully
Starting fresh Minikube cluster...
Minikube is ready!
```

---

### Deploy Our AI-Enhanced Demo

> **What I'm doing**: "Now we're deploying the same resilient infrastructure, but this time we'll replace traditional scaling with intelligent agents."

**Offline Mode (recommended for live demos)**
```bash
./scripts/deploy-offline.sh
```

**What happens behind the scenes:**
- Loads pre-built `resilience-demo:1.1` image from local cache
- Deploys both blue and green deployments with initial HPA configuration
- Sets up service routing (initially pointing to blue)
- Prepares the foundation for our AI agent to take control

> **Pause Point**: "Notice we're deploying with standard HPA first. In the next step, we'll remove HPA from blue and let our AI agent take control, while green continues using traditional scaling."

**Expected result after deployment:**
```
Namespace 'distributed-resilience' created
Blue deployment: 1/1 pods running
Green deployment: 1/1 pods running
HPAs configured for both deployments
Service routing traffic to BLUE
AI agent ready to deploy
```

---

## Step 2 – Prepare for AI Control

> **What I'm doing**: "Now I'm going to disable traditional HPA for blue and ensure our service is pointed to the deployment that will be under AI control."

```bash
kubectl -n distributed-resilience delete hpa hpa-web-blue || true
kubectl -n distributed-resilience patch svc web -p '{"spec":{"selector":{"app":"web","version":"blue"}}}'
```

**Command breakdown:**
- First command removes HPA from blue deployment (AI agent will take over)
- Second command ensures web service routes traffic to blue
- The `|| true` ensures the script continues even if HPA doesn't exist

> **What this means**: "Blue deployment is now 'unmanaged' by Kubernetes autoscaling. It will stay at exactly 1 replica until our AI agent makes scaling decisions. Green still uses traditional HPA as our control group."

**Expected result:**
```
hpa.autoscaling "hpa-web-blue" deleted
service/web patched
```

---

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

**Speaker Note**: "Keep this window visible. You'll see blue scaling controlled by our AI agent, while green responds to traditional HPA triggers."

---

## Step 4 – Monitor Resource Consumption

**Terminal Window 2: Live CPU Monitoring**
```bash
kubectl -n distributed-resilience top pods
```

**Current baseline readings:**
```
NAME                         CPU(cores)   MEMORY(bytes)   
web-blue-7d4b8c8f9d-xyz12    3m           58Mi
web-green-6c9d7e5a4b-abc34   2m           61Mi
```

> **What this shows**: "Both deployments are essentially idle right now. But our AI agent is watching these metrics continuously, ready to make intelligent scaling decisions based on trends, not just instant thresholds."

---

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
[AI Agent] Monitoring CPU trends and making scaling decisions
[AI Agent] Current: 1 replicas, CPU: 3%, Status: OPTIMAL
[AI Agent] Thresholds: Scale-up >90%, Scale-down <30%
```

---

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
[AI Agent] CPU spike detected: 95% (above 90% threshold)
[AI Agent] Trend analysis: Sustained high CPU for 30 seconds
[AI Agent] Decision: SCALE UP to 3 replicas (gradual scaling)
[AI Agent] Executing: kubectl scale deployment web-blue --replicas=3
[AI Agent] Monitoring impact of scaling decision...
```

**In the pods window:**
```
web-blue-7d4b8c8f9d-xyz12   1/1     Running   0          5m
web-blue-7d4b8c8f9d-new01   0/1     Pending   0          0s
web-blue-7d4b8c8f9d-new01   1/1     Running   0          15s
web-blue-7d4b8c8f9d-new02   0/1     Pending   0          30s
web-blue-7d4b8c8f9d-new02   1/1     Running   0          45s
```

> **What I'm explaining**: "Notice the intelligent scaling pattern. Instead of immediately jumping to 5 replicas, the agent scales gradually, monitors the impact, then makes further decisions based on whether the additional capacity resolves the load."

**After load test completes:**
```
[AI Agent] CPU normalizing: 25% (below 30% threshold for 60 seconds)
[AI Agent] Decision: SCALE DOWN to 1 replica (cost optimization)
[AI Agent] Executing: kubectl scale deployment web-blue --replicas=1
```

---

## Step 7 – Add Resilience Monitoring

> **What I'm doing**: "Let's add our failover watcher to see how AI-driven scaling works alongside our resilience patterns."

**Terminal Window 3: Failover Monitoring**
```bash
./scripts/failover-watcher.sh
```

**What you'll see:**
```
[watcher] Starting intelligent failover monitoring...
[watcher] blue_ready=3/3 green_ready=1/1 current_service=blue
[watcher] AI-scaled blue deployment healthy - no action needed
```

> **Pause Point**: "Now we have both intelligent scaling AND intelligent failover working together. The agent handles capacity decisions while the watcher handles availability decisions."

---

## Step 8 – Test AI Scaling During Failure Recovery

> **What I'm doing**: "Here's the ultimate test - what happens when our AI-controlled deployment fails completely, then recovers while under load?"

```bash
./scripts/simulate-failure.sh blue --outage 20
```

**What this demonstrates:**
- Complete blue deployment failure (all pods terminated)
- Failover watcher switches traffic to green
- After 20 seconds, blue pods restart
- AI agent resumes control of the recovered deployment

**Expected sequence of events:**

**Failure detection:**
```
[watcher] blue_ready=0/3 green_ready=1/1 current_service=blue
[watcher] BLUE deployment failed! Switching to GREEN...
[AI Agent] Deployment failure detected - pausing scaling decisions
```

**During outage:**
```
[watcher] Traffic successfully routed to GREEN deployment
[AI Agent] Waiting for blue deployment recovery...
```

**Recovery phase:**
```
[watcher] blue_ready=1/1 green_ready=1/1 current_service=green
[AI Agent] Blue deployment recovered - resuming intelligent scaling
[watcher] Both deployments healthy - maintaining current routing
```

> **What this teaches us**: "The AI agent is smart enough to pause its operations during infrastructure failures and resume once the underlying deployment is healthy. It works cooperatively with other resilience systems."

---

## Key Learning Points

### Evolution Beyond Traditional HPA
- **Traditional HPA**: Reactive scaling based on single metrics (CPU/memory)
- **AI-driven scaling**: Proactive decisions considering trends, cost, and business context
- **Gradual scaling**: Intelligent agents can implement sophisticated scaling patterns

### Intelligent Decision Making
- **Trend analysis**: Makes decisions based on sustained patterns, not instant spikes
- **Cost awareness**: Balances performance needs with resource optimization
- **Business logic**: Can incorporate custom rules like business hours, traffic patterns, or application-specific requirements

### Cooperative Resilience
- **Multiple agents**: Scaling agents work alongside failover watchers
- **Graceful coordination**: Systems pause and resume operations during infrastructure changes
- **Holistic approach**: Combines capacity management with availability management

### Production Implications
- **Reduced over-provisioning**: Smarter scaling reduces unnecessary resource allocation
- **Faster response times**: Predictive scaling can scale before problems occur
- **Cost optimization**: AI agents can make financially-aware scaling decisions
- **Custom business logic**: Scaling decisions can incorporate domain-specific requirements

---

## What We Just Accomplished

We demonstrated the **next generation of infrastructure automation** by building a system that:

1. **Makes intelligent scaling decisions** using AI-driven logic instead of simple thresholds
2. **Combines multiple automation systems** (scaling agents + failover watchers) that work cooperatively
3. **Handles complex failure scenarios** where AI systems gracefully pause and resume operations
4. **Optimizes for both performance and cost** through sophisticated decision-making algorithms
5. **Provides a foundation for custom business logic** in infrastructure operations

This represents the evolution from reactive infrastructure to **predictive, intelligent operations** - the foundation of truly autonomous systems.