# Intelligent Failover with AI Agents

This is the next step in my resilience journey. In my traditional failover demo, I showed how Kubernetes Horizontal Pod Autoscalers (HPA) and simple watchers reacted to thresholds: scaling pods when CPU exceeded 50% or failing over on binary health checks.

In this demo, I go further. I replace reactive automation with **AI-driven, context-aware operations**. Instead of rigid rules, I use an intelligent agent that can analyze workload patterns, anticipate problems, and make nuanced decisions that balance performance, cost, and user experience.

---

## 1. Intelligent Architecture

![Intelligent Architecture](./docs/architecture-intelligent.svg)

In my HPA demo, the architecture was straightforward: blue and green deployments, an HPA reacting to CPU, and a failover watcher looking at health checks.

Here, the design is more sophisticated:

* I still have **blue/green deployments**, but they are coordinated by an **AI-powered failover agent**.
* The **kagent controller** orchestrates all agents, providing CRDs and lifecycle management.
* **MCP servers** give my agent controlled access to Kubernetes resources.
* **OpenAI integration** supplies the reasoning engine that lets the agent think beyond simple thresholds.

The key difference is that this architecture allows for **proactive resilience**. Instead of reacting after a problem has already occurred, the system can anticipate issues, initiate failovers before users notice, and even refine its own decision-making over time.

---

## 2. Start with a Clean Environment

I always begin by resetting my cluster. In the traditional demo this was to wipe out HPAs and watchers. Here, I do the same so I can start fresh with my agentic setup.

```bash
./scripts/cleanup.sh --cluster
```

This completely deletes the Minikube cluster and ensures nothing is left behind.

---

## 3. Deploy the Intelligent Infrastructure

In the HPA demo, I deployed workloads and YAML-defined autoscalers. Now I deploy a richer, agentic infrastructure:

```bash
./mcp-failover-clean/scripts/setup-mcp-failover-clean.sh
```

This script sets up:

* **kagent controller** to manage agents
* **MCP servers** to let agents act on the cluster
* The **failover-agent**, my intelligent operations agent
* **Blue/green workloads**, just like before, but AI-managed
* **OpenAI integration**, so my agent can reason

When this finishes, I confirm that the blue deployment has 2 replicas running, green is on standby, and the service is exposed through Minikube.

---

## 4. Meet My AI Agent

I verify that the agent is ready:

```bash
kubectl wait --for=condition=Ready pod -l kagent=failover-agent -n kagent --timeout=90s
kubectl get agents -n kagent
```

The result shows:

```
NAME             MODELCONFIG   READY   ACCEPTED
failover-agent   openai-gpt4   True    True
```

In my old demo, the intelligence was just thresholds in YAML. Now it lives in this agent, which can reason about context, trends, and even cost implications.

---

## 5. Ask Basic Questions Through the UI

Instead of running raw `kubectl` queries, I now use the **kagent UI**.

I type:

```
What deployments are currently running in the 'mcp-failover-clean' namespace?
```

The agent responds:

```
There are two deployments in the 'mcp-failover-clean' namespace: 'web-blue' with 2 replicas and 'web-green' on standby with 0 replicas.
```

This is my first big contrast. In the HPA demo, I had to interpret raw CLI output. Here, the agent gives me an immediate, human-readable summary.

---

## 6. Delegate Monitoring Setup

Previously, monitoring was all on me. I had to watch CPU graphs and wait for the HPA to react. Now I can delegate that responsibility to the agent.

In the UI I type:

```
Set up continuous monitoring and alerting for issues like high CPU, memory, or pod crashes.
```

The agent replies that Prometheus and Alertmanager are needed, and asks if I want it to proceed. I say `Yes`.

If something is missing (like Prometheus Operator CRDs), the agent detects it, explains why it failed, and proposes a fix. I approve again.

This is **guided intelligence**. The agent doesn’t blindly act; it collaborates with me and explains its reasoning.

---

## 7. Simulate Degradation and Ask for a Decision

In my HPA demo, I stressed the blue deployment and waited for the autoscaler to add pods. Now, I simulate degradation but instead of just watching metrics, I ask the agent what I should do.

I run:

```bash
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": { "template": { "spec": { "containers": [{
    "name": "web",
    "env": [{"name": "SLOW_REQUESTS", "value": "40"}]
  }]}}}}'
```

Then I ask in the UI:

```
Our blue deployment is degraded. Should I failover to green?
```

The agent replies with reasoning:

```
Blue is experiencing high latency. Failing over to green is the optimal decision to maintain availability and prevent user impact. Do you want me to proceed?
```

I respond `Yes`, and the agent executes the failover.

Here, the difference is clear: the agent justifies its recommendation. My old watcher simply flipped traffic on a binary health check.

---

## 8. Grant Full Autonomy

Once I’ve seen the agent make good decisions, I take the next step: I trust it with autonomy.

In the UI I type:

```
From now on, automatically fix any issues like pod crashes or total failures without asking for my confirmation.
```

In the HPA demo, there was no way to do this—I had to encode thresholds up front. Here, I delegate authority.

---

## 9. Trigger a Crash and Watch Self-Healing

To prove the difference, I simulate a total crash of the blue deployment.

```bash
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": { "template": { "spec": { "containers": [{
    "name": "web",
    "env": [{"name": "POD_CRASH", "value": "true"}]
  }]}}}}'
```

I watch:

```bash
kubectl -n mcp-failover-clean get pods -w
```

The blue pods terminate. Instead of waiting for Kubernetes to restart them, the **agent immediately detects the crash, reasons about the impact, and initiates a failover to green automatically**.

This is what true self-healing looks like.

---

## 10. Summarize the Differences

At this stage I step back and compare the two approaches side by side:

| Aspect              | Traditional Demo      | Intelligent Demo               |
| ------------------- | --------------------- | ------------------------------ |
| **Decision Making** | Threshold rules       | Contextual reasoning           |
| **Scaling**         | Reactive CPU triggers | Predictive and adaptive        |
| **Failover**        | Binary watcher        | Guided or autonomous           |
| **Optimization**    | Single metric         | Balances cost, performance, UX |
| **Interaction**     | CLI and YAML          | Conversational UI              |

---

## 11. Cleanup

Once I finish the demo, I reset the environment:

```bash
./scripts/cleanup.sh --cluster
```

---

## What I Showcased

1. I built trust in the agent by starting with guided intelligence.
2. I delegated autonomy once I was confident in its decisions.
3. I demonstrated full self-healing, where the system fixed itself without my intervention.

Compared to my **traditional failover demo**, this intelligent version represents a paradigm shift: from **reactive automation** to **on-demand intelligence and autonomous remediation**.

My infrastructure no longer just reacts—it **thinks, reasons, and acts when I allow it to**.

---
