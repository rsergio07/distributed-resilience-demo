
# Cost Management Assumptions

This demo includes a simple way to reason about costs when designing for resilience.

**Assumptions (edit to your context):**
- Node price: USD 0.12 per vCPU-hour (example blended cost)
- Each pod requests 100m CPU (0.1 vCPU) and 128Mi memory
- HPA target: 50% CPU utilization
- Baseline reps: 1 per color (blue/green), scaling up to 5 during load

**Key takeaways:**
- Idle replicas cost money. Use HPA and scale-to-zero patterns for off-hours.
- Right-size requests/limits to avoid over-provisioning.
- Prefer testing failover by switching Service selectors instead of duplicating full capacity 24/7.

See `cost/calc_costs.py` to print a few scenarios.
