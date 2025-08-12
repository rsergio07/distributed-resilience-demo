# Distributed Resilience Demo (Kubernetes)

Demo for the talk **"Distributed Resilience: How to Design Systems That Don't Fail (Even When Everything Else Does)"**.

This repository showcases **resilience patterns**, **cost-aware design**, and **disaster recovery strategies** using Kubernetes.  
It is structured so anyone can **fork or clone** the repo, deploy the workloads locally, and reproduce the demo environment step-by-step.

---

## About This Demo

This project is a hands-on example of:

- **Blue/Green deployment switching** using Kubernetes `Service` selectors
- **Horizontal Pod Autoscaler (HPA)** to scale workloads up/down based on CPU usage
- **Pod failure simulation** to demonstrate recovery and failover strategies
- **FinOps mindset** with a cost estimation script (`cost/calc_costs.py`)
- **Offline-ready deployment** for conference/live demos without internet access

While designed for **live presentations**, it is also a self-contained learning resource for Kubernetes users, SREs, DevOps engineers, and students.

---

## Getting Started

You can either **fork** this repo to your own GitHub account or **clone** it locally.

### Requirements

- Colima or Docker Desktop  
- Minikube  
- kubectl  
- Python 3.11+  
- curl  

**Note:** This project has been tested with Colima (Docker runtime) on macOS, but it should work on Linux and Windows (with WSL2) with minimal changes.

---

## Deployment Options

### Option 1 – Online Mode

Pulls required images from the internet.

```bash
# Deploy
./scripts/deploy.sh

# Get the service URL
minikube service web -n distributed-resilience --url

# Send load to trigger HPA
./scripts/load-test.sh
```

### Option 2 – Offline Mode

Recommended for live demos so you don't have to rely on the internet connection or speed.

Prepare all required images locally:

```bash
# One-time preparation
./scripts/prepare-offline.sh
```

Deploy without internet access:

```bash
./scripts/deploy-offline.sh
```

---

## Runbooks

- [Runbook 1 – Blue/Green Failover](./RUNBOOK_FAILOVER.md)  
- [Runbook 2 – Agentic AI Autoscaling Demo](./RUNBOOK_AUTOSCALING.md)

---

## Contributing

Contributions are welcome! Please see `CONTRIBUTING.md` for details.

---

## License

This project is licensed under the MIT License – see `LICENSE.md` for details.