# Intelligent Failover with AI Agents

This runbook demonstrates the **next evolution of resilience patterns**—moving beyond reactive automation to **intelligent, context-aware operations**. While traditional HPA and failover systems react to thresholds, AI agents can analyze patterns, predict issues, and make nuanced decisions that balance performance, cost, and reliability.

**Prerequisites**: Complete the basic HPA runbook first to understand traditional patterns. This exercise builds on those concepts but uses an entirely different technical stack optimized for agentic operations.

---

### **Intelligent Architecture**

![Intelligent Architecture](./docs/architecture-intelligent.svg)

The intelligent failover approach builds upon traditional resilience but introduces a new layer of autonomy and reasoning through **AI-driven decision-making**. In this design, the deployments are still blue and green, but their scaling and failover are coordinated by an **AI-powered failover agent**.

The agent operates with context-aware intelligence: instead of reacting only to CPU spikes, it evaluates workload patterns, cost implications, and user impact before taking action. The agent is orchestrated by the **kagent controller**, which provides CRDs and lifecycle management, while **MCP servers** give the AI secure access to Kubernetes tools for real-time interaction. Finally, **OpenAI integration** supplies the reasoning engine that allows the system to make nuanced, human-like decisions.

This architecture excels in scenarios where **proactive resilience** is critical. The system can anticipate scaling needs before thresholds are crossed, initiate failover before users notice disruption, and adapt strategies over time as it learns from patterns. The trade-off is complexity: deploying and operating this intelligent layer requires more moving parts and trust in the AI's ability to balance performance, cost, and reliability.

---

## The Evolution: From Reactive to Intelligent

**Traditional Approach** (what you saw in the HPA runbook):
- HPA scales at 50% CPU (reactive)
- Failover watcher switches on binary health checks
- Same behavior every time, regardless of context

**Intelligent Approach** (what we'll demonstrate here):
- AI agent predicts load and scales proactively when queried
- Context-aware failover considering business impact
- On-demand analysis and optimization through API calls

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
   Your blue/green failover demo is ready!
   Blue deployment:  2 replicas running
   Green deployment: 0 replicas (standby)
   Service:          NodePort on minikube
```

---

## Step 3 – Meet Your AI Operations Agent

> **What I'm doing**: "Let's verify our AI agent is operational and understand what makes it different from traditional automation."

```bash
# Wait until the failover-agent pod is ready
kubectl wait --for=condition=Ready pod -l kagent=failover-agent -n kagent --timeout=90s

# Confirm agent status
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
- **On-demand intelligence**: Responds to API queries with sophisticated analysis

---

## Step 4 – Set Up Intelligent Monitoring

> **What I'm doing**: "Instead of watching simple metrics, let's observe how our AI agent analyzes and reasons about system state when we ask it to."

**Terminal Window 1: Agent Decision Log**
```bash
kubectl logs -f deployment/failover-agent -n kagent | grep -v "GET /health"
```

**Terminal Window 2: Traditional Pod Status** 
```bash
kubectl get pods -n mcp-failover-clean -w
```

**Terminal Window 3: Service Routing Status**
```bash
watch -n 3 'kubectl get svc web -n mcp-failover-clean -o jsonpath="{.spec.selector}" | jq'
```

> **What I'm explaining**: "Notice the agent only shows health checks initially. The real intelligence comes when we make API requests for analysis. Unlike traditional monitoring that constantly reacts, our AI agent provides on-demand intelligence."

---

## Step 5 – Demonstrate Predictive Scaling

> **What I'm doing**: "Traditional HPA waits for problems. Our agent predicts them when asked. Let's create changing conditions and then query the agent for intelligent analysis."

**Create a gradual load pattern:**
```bash
./mcp-failover-clean/scripts/gradual-load-test.sh 300 &
```

**Wait 2-3 minutes for load patterns to develop, then query the agent:**
```bash
# Get the service URL first
DEMO_URL=$(minikube service web -n mcp-failover-clean --url)

# Ask the agent to analyze trends (this is when the magic happens)
kubectl exec -n kagent deployment/failover-agent -c kagent -- curl -X POST localhost:8080/analyze \
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
```json
{
  "analysis": "Traffic pattern shows 15% increase over last 3 minutes",
  "current_metrics": {
    "response_time": "45ms trending upward",
    "cpu_utilization": "34% but accelerating",
    "memory_utilization": "within normal range"
  },
  "prediction": "70% chance of CPU spike in next 5-8 minutes",
  "recommendation": "Preemptive scaling of blue deployment",
  "reasoning": "Prevents performance degradation rather than reacting to it"
}
```

> **Key insight**: "See how the agent doesn't automatically react—it provides intelligent analysis when asked. This is on-demand intelligence, not constant automation."

**Monitor the agent logs** to see detailed reasoning:
```bash
kubectl logs deployment/failover-agent -n kagent --tail=20
```

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

# Wait for pods to restart with new config
kubectl rollout status deployment/web-blue -n mcp-failover-clean
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

**Expected intelligent analysis:**
```json
{
  "assessment": {
    "blue": {
      "cpu": "23%",
      "memory": "145MB", 
      "response_time": "180ms",
      "error_rate": "0.2%",
      "status": "degraded_performance"
    },
    "green": {
      "cpu": "12%",
      "memory": "132MB",
      "response_time": "45ms", 
      "error_rate": "0.0%",
      "status": "optimal"
    }
  },
  "recommendation": "Gradual traffic shift (30% to green)",
  "business_impact": "12% improvement in user satisfaction",
  "cost_impact": "Minimal (+$2.3/day)"
}
```

**Watch the agent logs** to see the reasoning process in action.

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

# Wait for rollout
kubectl rollout status deployment/web-blue -n mcp-failover-clean
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

**Expected intelligent decision making:**
```json
{
  "failover_assessment": {
    "blue_status": "Pods healthy, but UX degrading",
    "metrics": {
      "response_time": "340ms (baseline: 50ms)",
      "error_rate": "4.8% (SLA breach at 5%)",
      "user_impact": "HIGH (affects 1,200+ active sessions)"
    },
    "green_status": "Ready and optimal",
    "decision_matrix": {
      "technical_health": "Blue=OK, Green=EXCELLENT",
      "user_experience": "Blue=POOR, Green=OPTIMAL", 
      "business_impact": "HIGH if no action taken",
      "failover_risk": "LOW (green proven stable)"
    },
    "recommendation": "Immediate traffic switch to green",
    "execution": "Failover initiated"
  }
}
```

---

## Step 8 – Multi-Dimensional Optimization

> **What I'm doing**: "Here's where AI really shines—optimizing multiple constraints simultaneously. Let's give our agent a complex challenge that balances performance, cost, and reliability."

**Present the agent with an optimization challenge:**
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

**Expected sophisticated optimization:**
```json
{
  "optimization_analysis": {
    "current_state": {
      "blue": "2 replicas, handling 100% traffic",
      "green": "1 replica, standby",
      "cost": "$8.20/hour"
    },
    "load_prediction": {
      "expected_rps": "800 (current: 400)",
      "required_capacity": "4-6 replicas total",
      "peak_cpu": "~75% per pod"
    },
    "optimization_strategy": [
      "Pre-scale green to 3 replicas (cost: +$4.50/hr)",
      "Gradual traffic split 60% green, 40% blue", 
      "Scale blue to 2 replicas (adequate for reduced load)",
      "Monitor and adjust every 30 seconds"
    ],
    "predicted_outcomes": {
      "response_time": "68ms (target: <100ms)",
      "error_rate": "0.3% (target: <1%)",
      "availability": "99.97% (target: >99.9%)",
      "cost": "$11.80/hr (budget: $12.50/hr)"
    }
  }
}
```

---

## Step 9 – Learning and Adaptation

> **What I'm doing**: "Unlike static rules, our agent can reflect on what it's observed. Let's see how it summarizes its learning from this session."

**Ask the agent about its learning:**
```bash
kubectl exec -n kagent deployment/failover-agent -c main -- curl -X POST localhost:8080/insights \
  -H "Content-Type: application/json" \
  -d '{
    "query": "summarize_learnings",
    "session": "current_demo"
  }'
```

**Expected learning summary:**
```json
{
  "learning_summary": {
    "patterns_identified": [
      "Blue deployment shows 15% higher memory usage under load",
      "Green consistently outperforms on response time (avg 18% faster)",
      "Gradual traffic shifts cause less connection drops than instant switches",
      "Pre-emptive scaling reduces user-facing issues by ~60%"
    ],
    "updated_decision_rules": [
      "Prefer green for latency-sensitive workloads",
      "Begin scaling at 35% CPU (not 50%) for better user experience",
      "Use 70/30 traffic splits instead of 50/50 for testing", 
      "Factor memory trends into scaling decisions (not just CPU)"
    ],
    "confidence_improvements": {
      "failover_timing": "78% → 94%",
      "load_prediction": "65% → 89%",
      "cost_optimization": "72% → 87%"
    },
    "note": "Next session will apply these learnings automatically"
  }
}
```

---

## Step 10 – Understanding the Demo Architecture

> **What I'm doing**: "Let's examine what we actually built and how it differs from traditional approaches."

**Inspect the AI infrastructure:**
```bash
# See all the AI agents running
kubectl get agents -n kagent

# Check agent services and endpoints
kubectl get svc -n kagent

# Look at the actual workload
kubectl get all -n mcp-failover-clean
```

**Key architectural insights:**

1. **On-Demand Intelligence**: The AI agents don't continuously monitor—they provide intelligent analysis when queried via API
2. **Contextual Reasoning**: Each request can include business context, time sensitivity, and optimization goals
3. **Multi-Agent System**: Different agents handle different aspects (networking, scaling, observability)
4. **Learning Capability**: Agents can reflect on patterns and improve decision-making over time

---

## Step 11 – Cleanup and Reflection

> **What I'm doing**: "Let's clean up our environment and reflect on what we've accomplished."

```bash
kubectl delete namespace mcp-failover-clean
kubectl delete namespace kagent
```

---

## Key Differences: Traditional vs Intelligent Operations

| **Aspect** | **Traditional HPA + Watcher** | **AI Agent** |
|---|---|---|
| **Decision Making** | Threshold-based rules | Contextual reasoning via API calls |
| **Scaling Triggers** | React to current CPU | Predict future needs when asked |
| **Failover Logic** | Binary health checks | Multi-factor analysis on demand |
| **Optimization** | Single metric (CPU) | Balance performance, cost, reliability |
| **Adaptation** | Static configuration | Learning from queried scenarios |
| **Context Awareness** | None | Business impact, time of day, user patterns |
| **Response Model** | Continuous monitoring | On-demand intelligence |

---

## What We Accomplished

In this demo, we showcased **the future of infrastructure operations**:

### **On-Demand Intelligence**
- AI agents provide sophisticated analysis when queried
- No constant monitoring overhead—intelligence when you need it
- API-driven decision making with rich context

### **Contextual Decision Making**  
- Balanced technical health with business impact
- Considered user experience, not just system metrics
- Made nuanced decisions based on multiple factors

### **Adaptive Learning**
- Agents reflected on observed patterns
- Updated decision rules based on real-world observations
- Improved confidence in predictions over time

### **Business-Aligned Operations**
- Prioritized user experience over technical simplicity
- Made cost-conscious decisions without sacrificing quality
- Provided transparent reasoning for all actions

---

## The Paradigm Shift

**Traditional Approach**: "When CPU > 50%, add more pods"

**Intelligent Approach**: "When asked, analyze traffic patterns, response time trends, user behavior, cost implications, and business context to determine optimal resource allocation and routing strategy"

This represents the evolution from **reactive automation** to **on-demand intelligence**—systems that don't just follow rules, but provide sophisticated analysis when requested, understand context, learn from experience, and make decisions that align with business objectives.

Your infrastructure doesn't just react anymore—**it thinks, but only when you ask it to**.