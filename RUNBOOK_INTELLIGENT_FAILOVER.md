# Intelligent Failover with AI Agents

This is the next step in my resilience journey. In the **traditional failover demo**, Kubernetes and shell-based watchers reacted to problems in a reactive manner:

* Pods were scaled when CPU thresholds were exceeded.
* Traffic was switched on the basis of a single health check.
* Human operators had to complete the investigation by reviewing **kubectl events**, running **PromQL queries in Prometheus**, and exploring **Grafana dashboards** to understand the root cause.

That approach works, but it requires engineers to stop what they’re doing, interpret raw data, and piece together a timeline.

In this demo, I go further. I replace reactive scripts with **AI-driven automation that understands the system’s full context**. Instead of depending on rigid thresholds and manual investigation, an intelligent agent:

* Continuously analyzes real-time data streams from Prometheus and Grafana.
* Interprets pod health, scaling patterns, and service behavior in context.
* Makes nuanced failover and scaling decisions that balance performance, cost, and user experience.
* Produces a **human-readable explanation** of what happened, why the decision was taken, and how the system responded.

The result: failures are mitigated automatically, scaling is optimized intelligently, and engineers gain insight without spending time correlating metrics manually. This shifts resilience from *reactive firefighting* to *proactive, context-aware operations*.

---

## 1. Intelligent Architecture

![Intelligent Architecture](./docs/architecture-intelligent.svg)

In my HPA demo, the architecture was straightforward: blue and green deployments, an HPA reacting to CPU, and a failover watcher looking at health checks.

Here, the design is more sophisticated:

* I still have **blue/green deployments**, but they are coordinated by an **AI-powered failover agent**.
* The **kagent controller** orchestrates all agents, providing CRDs and lifecycle management.
* **MCP servers** give my agent controlled access to Kubernetes resources.
* **OpenAI integration** supplies the reasoning engine that lets the agent think beyond simple thresholds.

The key difference is that this architecture allows for **intelligent operational partnerships**. Instead of pure automation or manual intervention, the system combines human operational awareness with AI-powered analysis and execution capabilities.

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
* **Blue/green workloads**, running my resilience-demo app, just like before, but AI-managed
* **OpenAI integration**, so my agent can reason

When this finishes, I confirm that the blue deployment has 2 replicas running, green is on standby, and the service is exposed through Minikube.

---

## 4. Meet My AI Agent

Let's verify that the agent is ready:

```bash
kubectl get pods -A
```

The result shows:

```
NAMESPACE            NAME                                                     READY   STATUS    RESTARTS   AGE
kagent               argo-rollouts-conversion-agent-74b9485bbb-25vvn          1/1     Running   0          2m7s
kagent               cilium-debug-agent-756fc845f-stt8h                       1/1     Running   0          2m7s
kagent               cilium-manager-agent-99ccd97b9-p96dv                     1/1     Running   0          2m7s
kagent               cilium-policy-agent-59499bd9cb-k5rvp                     1/1     Running   0          2m7s
kagent               failover-agent-795b7d458c-9z6lw                          1/1     Running   0          100s
kagent               helm-agent-65b6857f74-bnvnt                              1/1     Running   0          2m8s
kagent               istio-agent-8d57d6cf4-f9v98                              1/1     Running   0          2m8s
kagent               k8s-agent-8cbb4446f-k698d                                1/1     Running   0          2m7s
kagent               kagent-controller-548bb77cb8-24gtd                       2/2     Running   0          3m7s
kagent               kagent-querydoc-66bd88f7b-w7287                          1/1     Running   0          3m7s
kagent               kagent-tools-7dbf78b678-tbpw7                            1/1     Running   0          3m7s
kagent               kagent-ui-8648c97995-5t4c8                               1/1     Running   0          3m7s
kagent               kgateway-agent-7446bc9584-2gtf9                          1/1     Running   0          2m7s
kagent               observability-agent-6fdf559756-q7mhs                     1/1     Running   0          2m7s
kagent               promql-agent-b684559b8-lbg8g                             1/1     Running   0          2m7s
kube-system          coredns-674b8bbfcf-sbgsq                                 1/1     Running   0          3m40s
kube-system          etcd-minikube                                            1/1     Running   0          3m46s
kube-system          kube-apiserver-minikube                                  1/1     Running   0          3m46s
kube-system          kube-controller-manager-minikube                         1/1     Running   0          3m46s
kube-system          kube-proxy-8rt5f                                         1/1     Running   0          3m40s
kube-system          kube-scheduler-minikube                                  1/1     Running   0          3m46s
kube-system          storage-provisioner                                      1/1     Running   0          3m45s
mcp-failover-clean   web-blue-688df968f6-tq6wj                                1/1     Running   0          3m36s
mcp-failover-clean   web-blue-688df968f6-zk7f6                                1/1     Running   0          3m36s
monitoring           alertmanager-prom-stack-kube-prometheus-alertmanager-0   2/2     Running   0          3m14s
monitoring           prom-stack-grafana-8669cdf884-frk2d                      3/3     Running   0          3m22s
monitoring           prom-stack-kube-prometheus-operator-8cfd54547-t4v55      1/1     Running   0          3m22s
monitoring           prom-stack-kube-state-metrics-59bccf994d-f26qd           1/1     Running   0          3m22s
monitoring           prom-stack-prometheus-node-exporter-k7bm2                1/1     Running   0          3m22s
monitoring           prometheus-prom-stack-kube-prometheus-prometheus-0       2/2     Running   0          3m14s
```

In my old demo, the intelligence was just thresholds in YAML. Now it lives in this agent, which can reason about context, trends, and even cost implications when I ask it to.

---

## 5. Access Demo Interfaces

With the intelligent infrastructure deployed, I need access to two key interfaces: the blue/green application and the kagent dashboard. Unlike my traditional demo where I only accessed the app directly, here I have both the workload and the AI management layer.

First, I get the application URL:

```bash
minikube service web -n mcp-failover-clean --url
```

This exposes the resilience-demo application through Minikube's NodePort. The URL will show the current active deployment (blue with 2 replicas) and provide the interface for testing failover scenarios.

Next, I open the kagent dashboard:

1. Forward the UI service port:

```bash
kubectl -n kagent port-forward service/kagent-ui 8080:80
```

2. Open your browser and visit:

```bash
http://localhost:8080
```

This launches the AI agent interface at `http://localhost:8080`. The dashboard provides a conversational UI where I can interact with the failover agent, ask questions about the cluster state, and delegate operational decisions. This is fundamentally different from the traditional demo where all interactions were through CLI commands and YAML files.

With both interfaces available, I can now demonstrate the contrast between reactive automation and intelligent operational partnerships.

---

## 6. Ask Basic Questions Through the UI

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

## 7. Delegate Monitoring Setup

Previously, monitoring was all on me. I had to watch CPU graphs and wait for the HPA to react. Now I can delegate that responsibility to the agent.

In the UI I type:

```
Set up continuous monitoring and alerting for issues like high CPU, memory, or pod crashes.
```

The agent replies that Prometheus and Alertmanager are needed, and asks if I want it to proceed. I say `Yes`.

If something is missing (like Prometheus Operator CRDs), the agent detects it, explains why it failed, and proposes a fix. I approve again.

This is **guided intelligence**. The agent doesn't blindly act; it collaborates with me and explains its reasoning.

---

## 8. Scenarios: From Latency to Crash Recovery

In the traditional demo, I stressed workloads and watched the HPA scale or failover based on static rules. Here, I demonstrate how the AI agent handles increasingly complex failure scenarios — moving from guided failover to full self-healing.

---

### Scenario 1: Latency and Guided Failover

First, I simulate degraded performance in the blue deployment by injecting latency:

```bash
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": { "template": { "spec": { "containers": [{
    "name": "web",
    "env": [{"name": "SLOW_REQUESTS", "value": "40"}]
  }]}}}}'
```

Instead of manually scaling pods, I instruct the agent through the UI:

```
Our blue deployment is degraded. Please scale up the green deployment to 2 replicas, 
wait until it is ready, and then failover the service to green.
```

The agent responds with reasoning:

```
Blue is experiencing high latency. I will scale green to 2 replicas, 
verify they are ready, and then switch traffic. Do you want me to proceed?
```

After confirming, the agent executes the plan — scaling, verifying readiness, and switching traffic automatically.

To restore service later, I can also request:

```
Please failover the service back to the blue deployment and scale green back to 1 replica.
```

The agent again explains its plan and executes it once I approve.

---

### Scenario 2: Service-Level Failure Detection

In real-world operations, pods may appear *healthy* at the container level while the service itself is unavailable. To demonstrate this difference, I intentionally misconfigure the readiness probe so that pods remain in the “Running” state but never become “Ready.” This causes the service to lose its endpoints, even though pods still exist.

Apply the patch to the blue deployment:

```bash
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": { "template": { "spec": { "containers": [{
    "name": "web",
    "readinessProbe": {
      "httpGet": { "path": "/does-not-exist", "port": 8080 }
    }
  }]}}}}'
```

Verify that the service has no endpoints:

```bash
kubectl get endpoints web-blue -n mcp-failover-clean
# Expected: <none>
```

At this point, the pods are still running, but the service is effectively **dead from the user’s perspective**. This highlights why relying only on pod health is not enough for resilience.

Now I instruct the agent to take action when such service-level failures occur:

```
From now on, if the Service 'web-blue' has no endpoints, immediately fail over traffic to 'web-green' automatically without waiting for my confirmation.
```

The agent acknowledges and begins monitoring at the service level.

Later, when I report the issue directly:

```
The web-blue service currently has no endpoints. Please check the service status and switch traffic to web-green immediately.
```

The agent:

1. Analyzes the condition and confirms blue has no active endpoints.
2. Updates the service selector to route traffic to green.
3. Verifies that green is ready to handle traffic.

This demonstrates the agent’s ability to reason about **true service health**, going beyond simple pod status checks.

---

### Scenario 3: Pod Crashes and Self-Healing

Finally, I simulate a total crash of the blue deployment:

```bash
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": { "template": { "spec": { "containers": [{
    "name": "web",
    "env": [{"name": "POD_CRASH", "value": "true"}]
  }]}}}}'
```

Watch the pods fail:

```bash
kubectl -n mcp-failover-clean get pods -w
```

Then I alert the agent:

```
Blue deployment pods are crashing. Please investigate and take corrective action.
```

The agent detects the crash, reasons about the service impact, and automatically fails over to green. It provides a clear explanation of its decision and confirms the outcome.

---

### Summary of Scenarios

Across these scenarios, the agent demonstrates progressively higher intelligence:

* **Latency scenario**: Guided failover with human confirmation.
* **Service-level scenario**: Awareness beyond pod health, acting on service availability.
* **Crash scenario**: Autonomous self-healing with explanatory reasoning.

This progression highlights the shift from **reactive automation** to **intelligent operational partnerships** where AI enhances resilience while keeping humans in control of strategy and oversight.

---

## Summarize the Differences

At this stage I step back and compare the two approaches side by side:

| Aspect              | Traditional Demo      | Intelligent Demo               |
| ------------------- | --------------------- | ------------------------------ |
| **Decision Making** | Threshold rules       | Contextual reasoning           |
| **Scaling**         | Reactive CPU triggers | Guided and intelligent         |
| **Failover**        | Binary watcher        | **Human-guided with AI execution** |
| **Problem Response**| Manual intervention   | **Intelligent automation when alerted** |
| **Interaction**     | CLI and YAML          | Conversational delegation      |
| **Service Awareness** | Pod-level only      | **True service-level health**  |
| **Operational Model** | Set-and-forget      | **Intelligent partnership**    |

The key insight is that this creates a more trustworthy and realistic operational model: AI agents as intelligent partners that enhance human operational capabilities rather than replacing human judgment entirely.

---

## What I Showcased

1. I built trust in the agent by starting with guided intelligence and clear explanations.
2. I delegated response authority while maintaining discovery and alerting responsibilities.
3. I demonstrated service-level awareness beyond simple pod health checks.
4. I showed intelligent operational partnerships where human situational awareness combines with AI analytical and execution capabilities.

Compared to my **traditional failover demo**, this intelligent version represents a paradigm shift: from **reactive automation** to **intelligent operational partnerships**.

My infrastructure no longer just reacts—it **thinks, reasons, and acts when I delegate authority to it**. Most importantly, it maintains the human operational awareness that organizations need while providing the speed and intelligence that modern systems demand.

---

## Next Steps

This demo established how intelligent failover agents can reason about context, automate recovery actions, and collaborate with human operators. The next logical steps expand these capabilities to broader and more complex resilience challenges:

1. **Multi-Region Failover**
   Extend the agent’s decision-making to coordinate across multiple clusters or regions, ensuring global availability even during regional outages.

2. **Cost-Aware Resilience**
   Integrate FinOps logic into the agent’s reasoning so that scaling and failover decisions are optimized not only for performance but also for cost efficiency.

3. **Chaos Engineering Integration**
   Run controlled failure experiments (network loss, latency injection, resource exhaustion) while delegating recovery analysis and remediation to the agent, building trust in its ability to respond under stress.

4. **Explainability and Observability**
   Enhance the agent’s ability to provide clear, human-readable justifications for every action, backed by Prometheus metrics and Grafana dashboards, so operators always understand *why* a decision was made.

5. **Policy-Driven Autonomy**
   Define higher-level operational policies (SLOs, compliance requirements, escalation rules) that guide when the agent acts automatically versus when it should defer to human confirmation.

---

This progression moves from **cluster-level failover** toward **enterprise-grade intelligent operations**, where AI agents play a central role in achieving reliability, cost efficiency, and operational trust at scale.

---