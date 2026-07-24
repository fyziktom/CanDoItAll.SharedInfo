#!/usr/bin/env python3
"""Create a simple cash pooling allocation model."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    entities = data.get("entities", [])
    surplus = []
    deficits = []
    standalone_interest_cost = 0.0
    standalone_deposit_income = 0.0

    for e in entities:
        cash = float(e.get("cash", 0))
        min_cash = float(e.get("min_cash", 0))
        overdraft = float(e.get("overdraft", 0))
        trapped = float(e.get("trapped_cash", 0))
        borrow_rate = float(e.get("borrowing_rate", 0))
        deposit_rate = float(e.get("deposit_rate", 0))
        transferable = max(0.0, cash - min_cash - trapped)
        deficit = max(0.0, min_cash + overdraft - cash)
        standalone_interest_cost += overdraft * borrow_rate
        standalone_deposit_income += transferable * deposit_rate
        if transferable > 0:
            surplus.append({"name": e.get("name"), "amount": transferable, "deposit_rate": deposit_rate})
        if deficit > 0:
            deficits.append({"name": e.get("name"), "amount": deficit, "borrowing_rate": borrow_rate})

    deficits.sort(key=lambda x: x["borrowing_rate"], reverse=True)
    total_surplus = sum(x["amount"] for x in surplus)
    remaining_pool = total_surplus
    allocations = []
    avoided_interest = 0.0
    for d in deficits:
        amount = min(remaining_pool, d["amount"])
        if amount > 0:
            allocations.append({"to_entity": d["name"], "amount": round(amount, 2), "avoided_rate": d["borrowing_rate"]})
            avoided_interest += amount * d["borrowing_rate"]
            remaining_pool -= amount

    lost_deposit_income = sum(x["amount"] * x["deposit_rate"] for x in surplus) if allocations else 0.0
    net_saving = avoided_interest - lost_deposit_income

    flags = []
    if total_surplus == 0:
        flags.append("No transferable surplus cash identified.")
    if deficits and total_surplus > 0:
        flags.append("Pooling can reduce overdraft/borrowing cost, but legal, tax, bank, and intercompany documentation must be reviewed.")
    if remaining_pool > 0:
        flags.append("Surplus remains after covering modeled deficits; define investment/debt-reduction policy.")
    if not flags:
        flags.append("No immediate pooling action from simplified data.")

    return {
        "total_transferable_surplus": round(total_surplus, 2),
        "total_deficit": round(sum(x["amount"] for x in deficits), 2),
        "remaining_surplus_after_allocations": round(remaining_pool, 2),
        "standalone_interest_cost": round(standalone_interest_cost, 2),
        "standalone_deposit_income": round(standalone_deposit_income, 2),
        "estimated_annual_avoided_interest": round(avoided_interest, 2),
        "estimated_annual_lost_deposit_income": round(lost_deposit_income, 2),
        "estimated_net_annual_saving": round(net_saving, 2),
        "allocations": allocations,
        "cfo_flags": flags,
    }


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Cash Pooling Opportunity Analysis", ""]
    for key in [
        "total_transferable_surplus", "total_deficit", "remaining_surplus_after_allocations",
        "estimated_annual_avoided_interest", "estimated_annual_lost_deposit_income", "estimated_net_annual_saving",
    ]:
        lines.append(f"- {key.replace('_', ' ').title()}: {result.get(key)}")
    lines.append("\n## Allocations")
    for a in result.get("allocations", []):
        lines.append(f"- Transfer {a['amount']} to {a['to_entity']} to avoid borrowing at {a['avoided_rate']:.2%}.")
    lines.append("\n## CFO flags")
    for flag in result.get("cfo_flags", []):
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze cash pooling opportunity.")
    parser.add_argument("input", type=Path, help="JSON cash pool case")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
