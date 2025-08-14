# Cost Management Assumptions

This demo includes a lightweight model for reasoning about operational costs when designing for resilience. The values used here are examples and should be adapted to match your actual pricing and workload characteristics.

In the baseline scenario, each Kubernetes node is priced at approximately USD 0.12 per vCPU-hour. A single pod requests 100m of CPU (0.1 vCPU) and 128Mi of memory. The Horizontal Pod Autoscaler is configured with a target CPU utilization of 50%, and each deployment—blue and green—starts with one replica and can scale up to five replicas during periods of load.

A few principles are worth noting. Idle replicas still generate cost, so adopting scale-to-zero patterns or carefully tuned HPA policies during off-hours can reduce unnecessary spend. Right-sizing pod requests and limits helps avoid over-provisioning, ensuring that resource allocations match actual demand. When testing failover scenarios, it is generally more cost-efficient to switch Service selectors rather than maintaining duplicate full-capacity deployments around the clock.

For practical exploration, the script at [`cost/calc_costs.py`](./cost/calc_costs.py) can be used to simulate and print example scenarios, allowing you to see how these assumptions play out under different scaling conditions.

---
