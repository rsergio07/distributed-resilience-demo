# Intelligent Failover with AI Agents

This runbook demonstrates the **next evolution of resilience patterns**—moving beyond reactive automation to **intelligent, context-aware operations**. While traditional HPA and failover systems react to thresholds, AI agents can analyze patterns, predict issues, and make nuanced decisions that balance performance, cost, and reliability.

**Prerequisites**: Complete the basic HPA runbook first to understand traditional patterns. This exercise builds on those concepts but uses an entirely different technical stack optimized for agentic operations.

---

### **Intelligent Architecture**

![Intelligent Architecture](./docs/architecture-intelligent.svg)

The intelligent failover approach builds upon traditional resilience but introduces a new layer of autonomy and reasoning through **AI-driven decision-making**. In this design, the deployments are still blue and green, but their scaling and failover are coordinated by an **AI-powered failover agent**.

The agent operates with context-aware intelligence: instead of reacting only to CPU spikes, it evaluates workload patterns, cost implications, and user impact before taking action. The agent is orchestrated by the **kagent controller**, which provides CRDs and lifecycle management, while **MCP servers** give the AI secure access to Kubernetes tools for real-time interaction. Finally, **OpenAI integration** supplies the reasoning engine that allows the system to make nuanced, human-like decisions.

This architecture excels in scenarios where **proactive resilience** is critical. The system can anticipate scaling needs before thresholds are crossed, initiate failover before users notice disruption, and adapt strategies over time as it learns from patterns. The trade-off is complexity: deploying and operating this intelligent layer requires more moving parts and trust in the AI’s ability to balance performance, cost, and reliability.

---

## The Evolution: From Reactive to Intelligent

**Traditional Approach** (what you saw in the HPA runbook):
- HPA scales at 50% CPU (reactive)
- Failover watcher switches on binary health checks
- Same behavior every time, regardless of context

**Intelligent Approach** (what we'll demonstrate here):
- AI agent predicts load and scales proactively
- Context-aware failover considering business impact
- Continuous learning and optimization

---

## Step 1 – Start with a Clean Environment

> **What I'm doing**: "We need a fresh cluster optimized for agentic operations. This environment includes the kagent system, MCP servers, and AI-powered agents."

```bash
./scripts/cleanup.sh --cluster
```

**What this does:**
- Destroys the existing cluster completely
- Removes all traditional HPA and watcher configurations
- Prepares for our agentic infrastructure

---

## Step 2 – Deploy the Intelligent Infrastructure

> **What I'm doing**: "Now we're deploying a completely different stack. Instead of simple scripts, we have AI agents that can understand context, learn patterns, and make sophisticated decisions."

```bash
./mcp-failover-clean/scripts/setup-mcp-failover-clean.sh
```

**What gets deployed:**
- **kagent controller**: The brain that manages AI agents
- **MCP servers**: Tools that give agents Kubernetes superpowers
- **failover-agent**: Our intelligent operations agent
- **Blue/green workloads**: Same apps, but now managed by AI
- **OpenAI integration**: Gives agents reasoning capabilities

**Expected output:**
```
🎯 Your blue/green failover demo is ready!
   Blue deployment:  2 replicas running
   Green deployment: 0 replicas (standby)
   Service:          NodePort on minikube
```

---

## Step 3 – Meet Your AI Operations Agent

> **What I'm doing**: "Let's verify our AI agent is operational and understand what makes it different from traditional automation."

```bash
# Check agent status
kubectl get agents -n kagent

# Examine the agent configuration
kubectl describe agent failover-agent -n kagent
```

**What you'll see:**
```
NAME             MODELCONFIG   READY   ACCEPTED
failover-agent   openai-gpt4   True    True
```

**Agent capabilities:**
- **Natural language reasoning**: Understands complex scenarios
- **Multi-factor analysis**: Considers CPU, memory, errors, latency, cost
- **Pattern recognition**: Learns from historical data
- **Context awareness**: Makes different decisions based on time, load patterns, business context

---

## Step 4 – Set Up Intelligent Monitoring

> **What I'm doing**: "Instead of watching simple metrics, let's observe how our AI agent analyzes and reasons about system state."

**Terminal Window 1: Agent Decision Log**
```bash
kubectl logs -f deployment/failover-agent -n kagent
```

**Terminal Window 2: Traditional Pod Status** 
```bash
kubectl get pods -n mcp-failover-clean -w
```

**Terminal Window 3: Service Routing Status**
```bash
watch -n 3 'kubectl get svc web -n mcp-failover-clean -o jsonpath="{.spec.selector}" | jq'
```

> **What I'm explaining**: "Notice we still monitor the same infrastructure, but now we also see the agent's reasoning process. It's not just 'CPU high, scale up'—it's 'CPU trending up, response time degrading, user complaints increasing, recommend gradual blue-to-green traffic shift.'"

---

## Step 5 – Demonstrate Predictive Scaling

> **What I'm doing**: "Traditional HPA waits for problems. Our agent predicts them. Let's simulate a scenario where the agent scales resources before issues occur."

**Create a gradual load pattern:**
```bash
./scripts/gradual-load-test.sh 300 &
```

**Query the agent for its analysis:**
```bash
# Get the service URL first
DEMO_URL=$(minikube service web -n mcp-failover-clean --url)

# Ask the agent to analyze trends
kubectl exec -n kagent deployment/failover-agent -c main -- curl -X POST localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "task": "analyze_scaling_needs",
    "context": {
      "service_url": "'$DEMO_URL'",
      "time_horizon": "10_minutes",
      "business_context": "demo_environment"
    }
  }'
```

**What the agent might report:**
```
[agent] Analyzing traffic patterns...
[agent] Detected 15% increase in request rate over last 3 minutes
[agent] Response time stable at 45ms but trending upward
[agent] Memory utilization: 34% (within normal range)
[agent] Prediction: 70% chance of CPU spike in next 5-8 minutes
[agent] Recommendation: Preemptive scaling of blue deployment
[agent] Executing gradual scale-up...
```

> **Key insight**: "See how it's not just reacting to current metrics, but analyzing trends and predicting future needs. This prevents performance degradation instead of responding to it."

---

## Step 6 – Intelligent Load Balancing

> **What I'm doing**: "Let's see how our agent makes sophisticated traffic routing decisions based on multiple factors, not just binary health checks."

**Introduce performance variance:**
```bash
# Simulate blue deployment having slight performance degradation
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "web",
          "env": [{"name": "SLOW_REQUESTS", "value": "20"}]
        }]
      }
    }
  }
}'
```

**Ask the agent to evaluate the situation:**
```bash
kubectl exec -n kagent deployment/failover-agent -c main -- curl -X POST localhost:8080/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "task": "assess_deployment_health",
    "deployments": ["web-blue", "web-green"],
    "metrics_to_consider": ["response_time", "error_rate", "cpu_usage", "user_experience"]
  }'
```

**Agent's intelligent analysis:**
```
[agent] Health assessment results:
[agent] Blue: CPU 23%, Memory 145MB, Avg Response: 180ms, Error Rate: 0.2%
[agent] Green: CPU 12%, Memory 132MB, Avg Response: 45ms, Error Rate: 0.0%
[agent] Analysis: Blue showing performance degradation but within acceptable thresholds
[agent] Recommendation: Gradual traffic shift (30% to green) to improve user experience
[agent] Business impact: Estimated 12% improvement in user satisfaction
[agent] Cost impact: Minimal (+$2.3/day)
[agent] Executing intelligent load balancing...
```

---

## Step 7 – Context-Aware Failover Decisions

> **What I'm doing**: "Now let's see how the agent handles complex failure scenarios that require business judgment, not just technical responses."

**Simulate a nuanced failure:**
```bash
# Create a scenario where blue is technically "healthy" but performing poorly
kubectl patch deployment web-blue -n mcp-failover-clean -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "web",
          "env": [
            {"name": "SLOW_REQUESTS", "value": "40"},
            {"name": "RANDOM_ERRORS", "value": "5"}
          ]
        }]
      }
    }
  }
}'
```

**Agent's contextual evaluation:**
```bash
kubectl exec -n kagent deployment/failover-agent -c main -- curl -X POST localhost:8080/failover-assessment \
  -H "Content-Type: application/json" \
  -d '{
    "scenario": "performance_degradation",
    "business_priority": "user_experience",
    "context": {
      "time_of_day": "peak_hours",
      "user_tolerance": "low",
      "failover_cost": "acceptable"
    }
  }'
```

**Intelligent decision making:**
```
[agent] Failover Assessment Report:
[agent] ================================
[agent] Blue Status: Pods healthy, but UX degrading
[agent] - Response time: 340ms (baseline: 50ms)
[agent] - Error rate: 4.8% (SLA breach at 5%)
[agent] - User impact: HIGH (affects 1,200+ active sessions)
[agent] 
[agent] Green Status: Ready and optimal
[agent] - Capacity available: 85%
[agent] - Performance baseline: EXCELLENT
[agent] 
[agent] Decision Matrix:
[agent] - Technical health: Blue=OK, Green=EXCELLENT
[agent] - User experience: Blue=POOR, Green=OPTIMAL
[agent] - Business impact: HIGH if no action taken
[agent] - Failover risk: LOW (green proven stable)
[agent] 
[agent] RECOMMENDATION: Immediate traffic switch to green
[agent] Executing failover in 3... 2... 1...
```

---

## Step 8 – Multi-Dimensional Optimization

> **What I'm doing**: "Here's where AI really shines—optimizing multiple constraints simultaneously. Let's give our agent a complex challenge that balances performance, cost, and reliability."

**Present the agent with a optimization challenge:**
```bash
kubectl exec -n kagent deployment/failover-agent -c main -- curl -X POST localhost:8080/optimize \
  -H "Content-Type: application/json" \
  -d '{
    "optimization_goal": "multi_objective",
    "constraints": {
      "max_response_time_ms": 100,
      "max_error_rate_percent": 1.0,
      "target_availability_percent": 99.9,
      "budget_limit_per_hour": 12.50
    },
    "current_scenario": {
      "expected_load": "2x_normal",
      "duration_minutes": 45,
      "user_sensitivity": "high"
    }
  }'
```

**Agent's sophisticated optimization:**
```
[agent] Multi-Objective Optimization Analysis
[agent] ==========================================
[agent] 
[agent] Current State:
[agent] - Blue: 2 replicas, handling 100% traffic
[agent] - Green: 1 replica, standby
[agent] - Cost: $8.20/hour
[agent] 
[agent] Load Prediction (2x normal for 45min):
[agent] - Expected RPS: 800 (current: 400)
[agent] - Required capacity: 4-6 replicas total
[agent] - Peak CPU: ~75% per pod
[agent] 
[agent] Optimization Strategy:
[agent] 1. Pre-scale green to 3 replicas (cost: +$4.50/hr)
[agent] 2. Gradual traffic split 60% green, 40% blue
[agent] 3. Scale blue to 2 replicas (adequate for reduced load)
[agent] 4. Monitor and adjust every 30 seconds
[agent] 
[agent] Predicted Outcomes:
[agent] ✅ Response time: 68ms (target: <100ms)
[agent] ✅ Error rate: 0.3% (target: <1%)
[agent] ✅ Availability: 99.97% (target: >99.9%)
[agent] ✅ Cost: $11.80/hr (budget: $12.50/hr)
[agent] 
[agent] Executing optimization plan...
```

---

## Step 9 – Learning and Adaptation

> **What I'm doing**: "Unlike static rules, our agent learns from each scenario. Let's see how it adapts its decision-making based on what it's observed."

**Ask the agent about its learning:**
```bash
kubectl exec -n kagent deployment/failover-agent -c main -- curl -X POST localhost:8080/insights \
  -H "Content-Type: application/json" \
  -d '{
    "query": "summarize_learnings",
    "session": "current_demo"
  }'
```

**Agent's learning summary:**
```
[agent] Learning Summary - Demo Session
[agent] ====================================
[agent] 
[agent] Patterns Identified:
[agent] 1. Blue deployment shows 15% higher memory usage under load
[agent] 2. Green consistently outperforms on response time (avg 18% faster)
[agent] 3. Gradual traffic shifts cause less connection drops than instant switches
[agent] 4. Pre-emptive scaling reduces user-facing issues by ~60%
[agent] 
[agent] Updated Decision Rules:
[agent] - Prefer green for latency-sensitive workloads
[agent] - Begin scaling at 35% CPU (not 50%) for better user experience  
[agent] - Use 70/30 traffic splits instead of 50/50 for testing
[agent] - Factor memory trends into scaling decisions (not just CPU)
[agent] 
[agent] Confidence Improvements:
[agent] - Failover timing: 78% → 94%
[agent] - Load prediction: 65% → 89%  
[agent] - Cost optimization: 72% → 87%
[agent]
[agent] Next session will apply these learnings automatically.
```

---

## Step 10 – Cleanup and Reflection

> **What I'm doing**: "Let's clean up our environment and reflect on what we've accomplished."

```bash
kubectl delete namespace mcp-failover-clean
kubectl delete namespace kagent
```

---

## Key Differences: Traditional vs Intelligent Operations

| **Aspect** | **Traditional HPA + Watcher** | **AI Agent** |
|---|---|---|
| **Decision Making** | Threshold-based rules | Contextual reasoning |
| **Scaling Triggers** | React to current CPU | Predict future needs |
| **Failover Logic** | Binary health checks | Multi-factor analysis |
| **Optimization** | Single metric (CPU) | Balance performance, cost, reliability |
| **Adaptation** | Static configuration | Continuous learning |
| **Context Awareness** | None | Business impact, time of day, user patterns |
| **Response Time** | Minutes (reactive) | Seconds (predictive) |

---

## What We Accomplished

In this demo, we showcased **the future of infrastructure operations**:

### **Predictive Operations**
- Scaled resources before problems occurred
- Prevented performance degradation instead of reacting to it
- Used pattern recognition to anticipate needs

### **Contextual Decision Making**  
- Balanced technical health with business impact
- Considered user experience, not just system metrics
- Made nuanced decisions based on multiple factors

### **Continuous Optimization**
- Simultaneously optimized performance, cost, and reliability
- Adapted strategies based on real-world observations
- Learned from each scenario to improve future decisions

### **Business-Aligned Operations**
- Prioritized user experience over technical simplicity
- Made cost-conscious decisions without sacrificing quality
- Provided transparent reasoning for all actions

---

## The Paradigm Shift

**Traditional Approach**: "When CPU > 50%, add more pods"

**Intelligent Approach**: "Analyzing traffic patterns, response time trends, user behavior, cost implications, and business context to determine optimal resource allocation and routing strategy"

This represents the evolution from **reactive automation** to **proactive intelligence**—systems that don't just follow rules, but understand context, learn from experience, and make decisions that align with business objectives.

Your infrastructure doesn't just react anymore—**it thinks**.