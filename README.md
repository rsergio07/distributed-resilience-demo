# Distributed Resilience Demo (Kubernetes)

Demo for the talk **"Distributed Resilience: How to Design Systems That Don't Fail (Even When Everything Else Does)"**.

This repository showcases **resilience patterns**, **cost-aware design**, and **disaster recovery strategies** using Kubernetes.  
It is structured so anyone can **fork or clone** the repo, deploy the workloads locally, and reproduce the demo environment.

---

## What Makes This Special

Unlike typical Kubernetes demos, this project demonstrates **next-generation resilience patterns**:

- **Agentic AI-Driven Scaling** - Custom Python agents make intelligent scaling decisions beyond simple CPU/memory thresholds
- **Advanced Blue/Green Patterns** - Automated failover with custom monitoring logic, not just basic deployments
- **Self-Healing Systems** - Workloads that automatically detect, respond to, and recover from failures
- **Cost-Aware Operations** - FinOps principles integrated into scaling and resource decisions
- **Production-Ready Patterns** - Real-world resilience strategies you can adapt for your own systems

---

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Service       │───▶│  Blue Deploy     │    │  Green Deploy   │
│  (Traffic       │    │  (AI Agent)      │    │     (HPA)       │
│   Routing)      │    │  1-5 replicas    │    │   1-N replicas  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌────────▼────────┐             │
         │              │  AI Mock Agent  │             │
         │              │ CPU Thresholds  │             │
         │              │ Custom Logic    │             │
         │              └─────────────────┘             │
         │                                              │
         └──────────────────────────────────────────────┘
                    ┌─────────────────────┐
                    │ Failover Watcher    │
                    │ Health Monitoring   │
                    │ Automatic Switching │
                    └─────────────────────┘
```

---

## About This Demo

This project demonstrates:

- **Blue/Green deployment switching** using Kubernetes `Service` selectors with intelligent failover logic
- **Horizontal Pod Autoscaler (HPA)** scaling under load for traditional workloads
- **Agentic AI mock scaling** that makes complex decisions without relying on HPA
- **Pod failure simulation** for recovery/failover testing with realistic scenarios
- **Cost estimation** using a FinOps mindset for resource optimization
- **Offline-ready deployments** for live demos without internet dependency

---

## Quick Start

Get up and running in less than 5 minutes:

```bash
# 1. Clone the repository
git clone https://github.com/rsergio07/distributed-resilience-demo.git
cd distributed-resilience-demo

# 2. Start with a clean environment
./scripts/cleanup.sh --cluster

# 3. Deploy the demo (offline mode recommended)
IMAGE_TAG=resilience-demo:1.1 ./scripts/deploy-offline.sh

# 4. Verify deployment
kubectl -n distributed-resilience get pods

# 5. Choose your adventure - pick a runbook and follow along!
```

---

## Demo Scenarios

Each scenario is designed to teach specific resilience patterns through hands-on experience:

### [Runbook 1 – Blue/Green Failover with HPA](./RUNBOOK_FAILOVER.md)
**What you'll learn:** Traditional HPA scaling combined with intelligent traffic routing
- Automatic pod scaling under CPU load
- Service failover when deployments fail
- Recovery patterns for production workloads
- **Best for:** Understanding foundational resilience patterns

### [Runbook 2 – Agentic AI-Driven Autoscaling](./RUNBOOK_AUTOSCALING.md) 
**What you'll learn:** Next-generation scaling with custom AI agents
- CPU threshold-based decision making
- Custom scaling logic beyond HPA capabilities
- Coexistence of different scaling strategies
- **Best for:** Advanced users exploring AI-driven operations

---

## Prerequisites

Before running any demo, ensure you have:

- **Colima** or **Docker Desktop**
- **Minikube** 
- **kubectl** 
- **Python 3.11+**
- **curl**

> This demo has been tested on macOS with Colima. Linux and Windows (WSL2) should also work with minimal adjustments.

---

## Technology Stack

- **Kubernetes** - Container orchestration platform
- **Minikube** - Local Kubernetes development environment  
- **Python 3.11+** - AI agent development and automation scripts
- **Docker** - Container runtime and image management
- **Horizontal Pod Autoscaler (HPA)** - Built-in Kubernetes scaling
- **Custom Monitoring Logic** - Failover detection and traffic routing
- **Bash Scripts** - Demo automation and environment management

---

## Use Cases

- **Learning**: Hands-on experience with advanced Kubernetes resilience patterns
- **Training**: Corporate workshops on distributed systems reliability  
- **Proof of Concept**: Demonstrate AI-driven operations capabilities
- **Testing**: Validate application behavior under controlled failure scenarios
- **Benchmarking**: Compare traditional vs. intelligent scaling approaches

---

## Contributing

I welcome contributions! Whether it's:

- Bug fixes and improvements
- Documentation enhancements  
- New resilience patterns and scenarios
- Additional automation scripts
- Test cases and validation scripts

Please see `CONTRIBUTING.md` for details on our contribution process.

---

## License

This project is licensed under the MIT License – see `LICENSE.md` for details.

---

## Star This Repository

If this demo helped you understand distributed resilience patterns, please star the repository to help others discover it!