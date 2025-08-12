# Distributed Resilience Demo (Kubernetes)

Demo for the talk **"Distributed Resilience: How to Design Systems That Don't Fail (Even When Everything Else Does)"**.

This repository showcases **resilience patterns**, **cost-aware design**, and **disaster recovery strategies** using Kubernetes.  
It is structured so anyone can **fork or clone** the repo, deploy the workloads locally, and reproduce the demo environment.

---

## About This Demo

This project demonstrates:

- **Blue/Green deployment switching** using Kubernetes `Service` selectors
- **Horizontal Pod Autoscaler (HPA)** scaling under load
- **Pod failure simulation** for recovery/failover
- **Agentic AI mock scaling** without HPA
- **Cost estimation** using a FinOps mindset
- **Offline-ready deployments** for live demos

---

## Prerequisites

Before running any demo, ensure you have:

- Colima or Docker Desktop
- Minikube
- kubectl
- Python 3.11+
- curl

> This demo has been tested on macOS with Colima. Linux and Windows (WSL2) should also work with minimal adjustments.

---

## How to Use

All demo scenarios are documented in dedicated **Runbooks**.  
Each runbook provides:
- Purpose of the scenario
- Terminal-by-terminal instructions
- Expected outcomes

### Available Runbooks

- [Runbook 1 – Blue/Green Failover with HPA](./RUNBOOK_FAILOVER.md)  
- [Runbook 2 – Agentic AI-Driven Autoscaling](./RUNBOOK_AUTOSCALING.md)

---

## Contributing

We welcome contributions! Please see `CONTRIBUTING.md` for details.

---

## License

This project is licensed under the MIT License – see `LICENSE.md` for details.