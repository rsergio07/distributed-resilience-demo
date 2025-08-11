# **Distributed Resilience Demo (Kubernetes)**

Demo for the talk **"Distributed Resilience: How to design systems that don't fail (even when everything else does)"**.

## **Objective**

Demonstrate resilience and *cost-aware design* using:

* Blue/Green switching via Kubernetes `Service` selector
* Horizontal Pod Autoscaler (HPA) per deployment
* Failure simulation (deleting pods)
* Simple cost estimation (FinOps mindset)

## **Requirements**

* Docker, `kubectl`, and Minikube
* Python 3.11+
* `curl`

## **Quick Start**

```bash
# 1) Start and deploy
./scripts/deploy.sh

# 2) Open the URL
minikube service web -n distributed-resilience --url

# 3) Send load (trigger autoscaling)
./scripts/load-test.sh

# 4) Simulate failure in 'blue' (pods deleted and recreated)
./scripts/simulate-failure.sh blue

# 5) Manually switch to 'green' (failover)
./scripts/switch.sh green
```

> Tip: Watch `kubectl -n distributed-resilience get hpa,pods -w` in another terminal to monitor scaling in real-time.

## **Cost Management (illustrative)**

Edit `cost/cost_assumptions.md` and run:

```bash
python cost/calc_costs.py
```

This will display different monthly cost scenarios:

* Always-on Blue only
* Always-on Blue+Green
* Peak scaling with HPA
* Scale-to-zero off-hours

## **Extending to Public Cloud**

* Push the image to a container registry (GHCR, ECR, IBM Cloud Container Registry)
* Deploy in 2+ regions (e.g., us-east / us-west) with the same `Service`/Ingress rules
* Monitor costs with Kubecost, AWS Cost Explorer, or IBM Cloud Cost Estimator
* Automate deployments with GitHub Actions

## **Cleanup**

```bash
kubectl delete ns distributed-resilience
# or
minikube delete
```

---