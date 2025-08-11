
# Simple cost scenarios for the demo (illustrative only)
# Run: python cost/calc_costs.py

NODE_PRICE_PER_VCPU_HOUR = 0.12  # USD
POD_CPU_REQUEST = 0.1  # vCPU (100m)
HOURS_PER_MONTH = 730

def monthly_cost(replicas: int) -> float:
    vcpu = replicas * POD_CPU_REQUEST
    return vcpu * NODE_PRICE_PER_VCPU_HOUR * HOURS_PER_MONTH

scenarios = {
    "Always-on blue (1 pod)": monthly_cost(1),
    "Always-on blue+green (2 pods)": monthly_cost(2),
    "Peak 5 pods for 2h/day + 1 pod rest": (monthly_cost(5) * (2 * 30) / 730) + (monthly_cost(1) * (730 - 60) / 730),
    "Scale-to-zero off-hours (8h/day off)": monthly_cost(1) * ((730 - (8 * 30)) / 730),
}

print("Illustrative monthly costs (USD):")
for k, v in scenarios.items():
    print(f"- {k}: ${v:.2f}")
