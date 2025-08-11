#!/usr/bin/env python3
"""
Cost scenarios for the demo with savings vs a chosen baseline.

Usage:
  python3 cost/calc_costs.py                 # baseline = "Always-on blue+green"
  python3 cost/calc_costs.py "Always-on blue (1 pod)"
  BASELINE="Peak 5 pods for 2h/day + 1 pod rest" python3 cost/calc_costs.py
"""

import os
import sys

# -------- Assumptions (edit these to your reality) -----------------
NODE_PRICE_PER_VCPU_HOUR = 0.12   # USD per vCPU-hour (blended)
POD_CPU_REQUEST_VCPU     = 0.10   # 100m = 0.1 vCPU per pod
HOURS_PER_MONTH          = 730    # ~365*24/12

# Workload patterns
DAYS_PER_MONTH           = 30
PEAK_HOURS_PER_DAY       = 2      # hours/day at peak scale
OFF_HOURS_PER_DAY        = 8      # hours/day you can scale to zero (nights, weekends, labs)
BASELINE_DEFAULT         = "Always-on blue+green (2 pods)"
# -------------------------------------------------------------------

def monthly_cost_for_replicas(replicas: float) -> float:
    vcpu = replicas * POD_CPU_REQUEST_VCPU
    return vcpu * NODE_PRICE_PER_VCPU_HOUR * HOURS_PER_MONTH

def fmt_usd(x: float) -> str:
    return f"${x:,.2f}"

def main():
    baseline_arg = os.environ.get("BASELINE") or (sys.argv[1] if len(sys.argv) > 1 else BASELINE_DEFAULT)

    # Scenarios
    always_on_blue   = monthly_cost_for_replicas(1)  # 1 replica 24/7
    always_on_both   = monthly_cost_for_replicas(2)  # blue + green 24/7

    # Peak: 5 replicas for PEAK_HOURS_PER_DAY, else 1 replica
    peak_hours = PEAK_HOURS_PER_DAY * DAYS_PER_MONTH
    non_peak_hours = HOURS_PER_MONTH - peak_hours
    peak_cost = (monthly_cost_for_replicas(5) * (peak_hours / HOURS_PER_MONTH)) + \
                (monthly_cost_for_replicas(1) * (non_peak_hours / HOURS_PER_MONTH))

    # Scale-to-zero off-hours: 0 replicas for OFF_HOURS_PER_DAY, else 1 replica
    off_hours = OFF_HOURS_PER_DAY * DAYS_PER_MONTH
    on_hours  = HOURS_PER_MONTH - off_hours
    scale_to_zero_cost = monthly_cost_for_replicas(1) * (on_hours / HOURS_PER_MONTH)

    scenarios = {
        "Always-on blue (1 pod)": always_on_blue,
        "Always-on blue+green (2 pods)": always_on_both,
        "Peak 5 pods for 2h/day + 1 pod rest": peak_cost,
        "Scale-to-zero off-hours (8h/day off)": scale_to_zero_cost,
    }

    # Baseline selection
    if baseline_arg not in scenarios:
        print("Available scenarios as baseline:")
        for name in scenarios:
            print(f" - {name}")
        print(f'\nInvalid baseline: "{baseline_arg}"')
        sys.exit(1)

    baseline_cost = scenarios[baseline_arg]

    # Output
    print("Assumptions:")
    print(f"- vCPU price: ${NODE_PRICE_PER_VCPU_HOUR}/vCPU-hour")
    print(f"- Pod CPU request: {POD_CPU_REQUEST_VCPU*100:.0f}m")
    print(f"- Hours/month: {HOURS_PER_MONTH}")
    print(f"- Peak hours/day: {PEAK_HOURS_PER_DAY}, Off-hours/day: {OFF_HOURS_PER_DAY}")
    print(f"- Baseline: {baseline_arg}\n")

    print(f"{'Scenario':<45} {'Monthly Cost':>14}  {'Savings vs Baseline':>21}")
    print("-" * 84)
    for name, cost in scenarios.items():
        savings = (baseline_cost - cost) / baseline_cost * 100 if baseline_cost > 0 else 0.0
        sign = "+" if savings > 0 else ""
        print(f"{name:<45} {fmt_usd(cost):>14}  {sign}{savings:>6.1f}%")

if __name__ == "__main__":
    main()
