#!/usr/bin/env python3
"""Evaluate an investment case using NPV, IRR, payback, and sensitivity."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List, Optional


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def npv(initial_investment: float, cash_flows: List[float], rate: float, terminal_value: float = 0.0) -> float:
    value = -initial_investment
    for i, cf in enumerate(cash_flows, start=1):
        value += cf / ((1 + rate) ** i)
    if terminal_value:
        value += terminal_value / ((1 + rate) ** len(cash_flows))
    return value


def irr(initial_investment: float, cash_flows: List[float], terminal_value: float = 0.0) -> Optional[float]:
    flows = [-initial_investment] + list(cash_flows)
    if terminal_value and len(flows) > 1:
        flows[-1] += terminal_value
    if not any(x > 0 for x in flows) or not any(x < 0 for x in flows):
        return None

    low, high = -0.99, 10.0
    for _ in range(200):
        mid = (low + high) / 2
        value = sum(cf / ((1 + mid) ** i) for i, cf in enumerate(flows))
        if abs(value) < 1e-7:
            return mid
        low_value = sum(cf / ((1 + low) ** i) for i, cf in enumerate(flows))
        if (low_value > 0 and value > 0) or (low_value < 0 and value < 0):
            low = mid
        else:
            high = mid
    return mid


def payback(initial_investment: float, cash_flows: List[float], rate: float | None = None) -> Optional[float]:
    cumulative = -initial_investment
    previous = cumulative
    for year, cf in enumerate(cash_flows, start=1):
        adjusted_cf = cf / ((1 + rate) ** year) if rate is not None else cf
        cumulative += adjusted_cf
        if cumulative >= 0:
            needed = -previous
            fraction = needed / adjusted_cf if adjusted_cf else 0
            return round((year - 1) + fraction, 2)
        previous = cumulative
    return None


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    initial = float(data.get("initial_investment", 0))
    rate = float(data.get("discount_rate", 0.1))
    flows = [float(x) for x in data.get("cash_flows", [])]
    terminal = float(data.get("terminal_value", 0))

    base_npv = npv(initial, flows, rate, terminal)
    base_irr = irr(initial, flows, terminal)
    base_payback = payback(initial, flows)
    discounted_payback = payback(initial, flows, rate)

    sens = data.get("sensitivity", {}) or {}
    multipliers = sens.get("cash_flow_multipliers", [0.75, 1.0, 1.25])
    rates = sens.get("discount_rates", [rate])
    sensitivity_rows = []
    for multiplier in multipliers:
        scaled = [cf * float(multiplier) for cf in flows]
        for r in rates:
            r = float(r)
            sensitivity_rows.append({
                "cash_flow_multiplier": float(multiplier),
                "discount_rate": r,
                "npv": round(npv(initial, scaled, r, terminal), 2),
                "payback_years": payback(initial, scaled, r),
            })

    flags = []
    if base_npv < 0:
        flags.append("Base-case NPV is negative at the supplied discount rate.")
    if base_payback is None:
        flags.append("Investment does not pay back within the modeled cash-flow period.")
    if base_irr is not None and base_irr < rate:
        flags.append("IRR is below the supplied discount rate/hurdle rate.")
    if initial > sum(max(0, cf) for cf in flows):
        flags.append("Initial investment is large relative to total modeled positive cash flows; validate assumptions carefully.")
    if not flags:
        flags.append("Base-case financial metrics are acceptable; still test liquidity, execution risk, and strategic fit.")

    return {
        "name": data.get("name", "investment"),
        "initial_investment": initial,
        "discount_rate": rate,
        "npv": round(base_npv, 2),
        "irr": None if base_irr is None else round(base_irr, 4),
        "payback_years": base_payback,
        "discounted_payback_years": discounted_payback,
        "sensitivity": sensitivity_rows,
        "cfo_flags": flags,
    }


def to_markdown(result: Dict[str, Any]) -> str:
    lines = [f"# Investment Appraisal: {result.get('name')}", ""]
    for key in ["initial_investment", "discount_rate", "npv", "irr", "payback_years", "discounted_payback_years"]:
        lines.append(f"- {key.replace('_', ' ').title()}: {result.get(key)}")
    lines.append("\n## CFO flags")
    for flag in result.get("cfo_flags", []):
        lines.append(f"- {flag}")
    lines.append("\n## Sensitivity")
    lines.append("| Cash flow multiplier | Discount rate | NPV | Discounted payback years |")
    lines.append("|---:|---:|---:|---:|")
    for row in result.get("sensitivity", []):
        lines.append(f"| {row['cash_flow_multiplier']:.2f} | {row['discount_rate']:.4f} | {row['npv']:.2f} | {row['payback_years']} |")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Evaluate an investment case.")
    parser.add_argument("input", type=Path, help="JSON investment case")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
