# **Distributed Resilience Demo (Kubernetes)**

Demo for the talk **"Distributed Resilience: How to Design Systems That Don't Fail (Even When Everything Else Does)"**.

This repository showcases **resilience patterns**, **cost-aware design**, and **disaster recovery strategies** using Kubernetes.  
It is structured so anyone can **fork or clone** the repo, deploy the workloads locally, and reproduce the demo environment step-by-step.

---

## **About This Demo**

This project is a hands-on example of:

- **Blue/Green deployment switching** using Kubernetes `Service` selectors.
- **Horizontal Pod Autoscaler (HPA)** to scale workloads up/down based on CPU usage.
- **Pod failure simulation** to demonstrate recovery and failover strategies.
- **FinOps mindset** with a cost estimation script (`cost/calc_costs.py`).
- **Offline-ready deployment** for conference/live demos without relying on internet access.

While designed for **live presentations**, it is also a self-contained learning resource for Kubernetes users, SREs, DevOps engineers, and students.

---

## **Getting Started**

You can either **fork** this repo to your own GitHub account or **clone** it locally:

```bash
# Clone directly
git clone https://github.com/YOUR-USERNAME/distributed-resilience-demo.git

# Or fork via GitHub UI, then:
git clone https://github.com/YOUR-FORK/distributed-resilience-demo.git
````

---

## **Requirements**

* [Colima](https://github.com/abiosoft/colima) or Docker Desktop
* [Minikube](https://minikube.sigs.k8s.io/docs/)
* `kubectl`
* Python **3.11+**
* `curl`

> 💡 This project has been tested with Colima (Docker runtime) on macOS, but should work on Linux and Windows (with WSL2) with minimal changes.

---

## **Deployment Options**

### **Option 1: Online Mode**

Uses internet access to pull required images.

```bash
# Deploy
./scripts/deploy.sh

# Get the service URL
minikube service web -n distributed-resilience --url

# Send load to trigger HPA
./scripts/load-test.sh
```

---

### **Option 2: Offline Mode (Recommended for Live Demos)**

Prepare all required images locally:

```bash
# One-time image preparation
./scripts/prepare-offline.sh
```

Deploy without internet access:

```bash
./scripts/deploy-offline.sh
```

---

## **Suggested Terminal Setup for Monitoring**

* **Terminal A:** Deployments and simulations
* **Terminal B:** Watch scaling events

  ```bash
  kubectl -n distributed-resilience get hpa,pods -w
  ```
* **Terminal C:** CPU usage metrics

  ```bash
  kubectl -n distributed-resilience top pods
  ```

---

## **Failure Simulation**

Delete pods from the blue deployment and watch them recover:

```bash
./scripts/simulate-failure.sh blue
```

Switch traffic to green manually:

```bash
./scripts/switch.sh green
```

---

## **Cost Simulation**

Estimate monthly costs under different scaling policies:

```bash
python3 cost/calc_costs.py
```

Scenarios:

* Always-on Blue only (1 pod)
* Always-on Blue+Green (2 pods)
* Peak scaling with HPA
* Scale-to-zero during off-hours

Edit `cost/cost_assumptions.md` to adjust parameters.

---

## **Cleanup**

Delete only the namespace:

```bash
kubectl delete ns distributed-resilience
```

Full reset (removes Minikube cluster):

```bash
./scripts/cleanup.sh --cluster
```

---

## **Contributing**

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## **License**

This project is licensed under the MIT License – see the [LICENSE.md](LICENSE.md) file for details.

---