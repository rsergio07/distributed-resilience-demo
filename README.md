# Distributed Resilience Demo: Production-Grade Kubernetes

**Design Kubernetes systems that withstand failure—even under extreme conditions.**

This repository is a hands-on lab for building **production-grade resilience** in Kubernetes. It goes far beyond basic tutorials, guiding you through advanced patterns that enable intelligent, autonomous, and cost-aware infrastructure. Inspired by the talk *"Distributed Resilience: How to Design Systems That Don't Fail (Even When Everything Else Does),"* this project demonstrates how to build systems that recover gracefully, adapt intelligently, and operate efficiently under pressure.

---

## Why This Demo Matters

Most Kubernetes demos focus on simple deployments and reactive scaling. This project focuses on **survivability and autonomy**. You'll build infrastructure that:

- Anticipates and mitigates failures before they escalate.
- Makes intelligent decisions based on business context, not just metrics.
- Recovers automatically without human intervention.
- Optimizes cost and performance using FinOps principles.

This is not a proof of concept—it’s a deployable, production-grade blueprint.

---

## System Architecture

![Architecture Diagram](./architecture-diagram.png)

The demo architecture is built around **redundancy, autonomy, and intelligent failover**:

- Two identical deployments (blue and green) provide high availability.
- A central Kubernetes service routes traffic and can switch instantly between deployments.
- The **blue deployment** is scaled by a custom Python-based AI agent that considers trends, cost, and business logic.
- The **green deployment** uses traditional Kubernetes HPA (Horizontal Pod Autoscaler) for reactive scaling.
- A **failover watcher** continuously monitors both deployments and orchestrates traffic switching when failures are detected.

This architecture enables real-time decision-making, proactive recovery, and seamless user experience—even during infrastructure disruptions.

---

## What You'll Learn

This project is designed to give you hands-on experience with advanced resilience techniques. You’ll explore:

- **Blue/Green Deployment Switching**  
  Implement intelligent failover logic that goes beyond basic service selectors.

- **HPA vs. AI-Driven Autoscaling**  
  Compare traditional autoscaling with agentic scaling that incorporates cost and business context.

- **Failure Simulation and Recovery**  
  Trigger realistic pod failures and observe autonomous recovery mechanisms.

- **FinOps Integration**  
  Use cost estimation to guide resource optimization and scaling decisions.

- **Offline Operation**  
  Run the entire demo without internet access to focus on architecture and logic.

Each scenario is designed to reinforce practical skills and deepen your understanding of resilient system design.

---

## Quick Start

Deploy the demo environment in minutes:

1. **Clone the repository**
   ```bash
   git clone https://github.com/rsergio07/distributed-resilience-demo.git
   cd distributed-resilience-demo
   ```

2. **Clean the environment**
   ```bash
   ./scripts/cleanup.sh --cluster
   ```

3. **Deploy the demo**
   ```bash
   ./scripts/deploy-offline.sh
   ```

4. **Verify deployment**
   ```bash
   kubectl -n distributed-resilience get pods
   ```

5. **Start a scenario**
   ```bash
   open RUNBOOK_FAILOVER.md
   ```

---

## Learning Paths

Choose a runbook based on your goals and experience level. Each runbook is a guided scenario that teaches specific resilience patterns under controlled failure conditions.

### Runbook 1: Blue/Green Failover with HPA

This foundational scenario introduces:

- Automatic scaling under load using Kubernetes HPA.
- Intelligent service failover when deployments become unhealthy.
- Zero-downtime deployment switching using service redirection.

**Recommended for:** Teams new to advanced Kubernetes patterns who want to understand how traditional and intelligent systems can work together.

---

### Runbook 2: AI-Driven Autoscaling

This advanced scenario explores:

- Cost-aware scaling decisions using a custom Python agent.
- Predictive infrastructure management based on historical trends.
- Autonomous decision-making that incorporates business logic.

**Recommended for:** Experienced users and teams exploring AI-driven operations and intelligent infrastructure design.

---

## Additional Resources

- **Runbooks:** Step-by-step guides for each scenario, located in the root directory.
- **Scripts:** Automation tools for deployment, cleanup, and simulation.
- **Architecture Diagram:** Visual reference for system components and traffic flow.
- **Offline Mode:** All dependencies are bundled for isolated environments.

---