#!/usr/bin/env python3
"""Allocate shared costs to departments based on explicit drivers."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    departments = data.get("departments", [])
    shared_costs = data.get("shared_costs", [])
    results = []
    allocations_by_department = {d["name"]: 0.0 for d in departments}
    allocation_detail = []

    for cost in shared_costs:
        driver = cost.get("driver")
        amount = float(cost.get("amount", 0))
        total_driver = sum(float(d.get(driver, 0)) for d in departments)
        if total_driver <= 0:
            allocation_detail.append({"cost": cost.get("name"), "warning": f"Driver {driver} has zero total; cost not allocated."})
            continue
        for d in departments:
            share = float(d.get(driver, 0)) / total_driver
            allocated = amount * share
            allocations_by_department[d["name"]] += allocated
            allocation_detail.append({
                "cost": cost.get("name"),
                "department": d["name"],
                "driver": driver,
                "driver_value": float(d.get(driver, 0)),
                "allocated_amount": round(allocated, 2),
            })

    for d in departments:
        revenue = float(d.get("revenue", 0))
        direct_costs = float(d.get("direct_costs", 0))
        allocated = allocations_by_department[d["name"]]
        pre_margin = revenue - direct_costs
        post_margin = pre_margin - allocated
        results.append({
            "department": d["name"],
            "revenue": round(revenue, 2),
            "direct_costs": round(direct_costs, 2),
            "pre_allocation_margin": round(pre_margin, 2),
            "allocated_shared_costs": round(allocated, 2),
            "post_allocation_margin": round(post_margin, 2),
            "pre_allocation_margin_pct": None if revenue == 0 else round(pre_margin / revenue, 4),
            "post_allocation_margin_pct": None if revenue == 0 else round(post_margin / revenue, 4),
        })

    flags = []
    for r in results:
        if r["pre_allocation_margin"] >= 0 and r["post_allocation_margin"] < 0:
            flags.append(f"{r['department']} becomes loss-making after shared cost allocation; review driver fairness and controllability.")
        if r["pre_allocation_margin"] < 0:
            flags.append(f"{r['department']} is loss-making before shared cost allocation; this is an operating issue, not only overhead allocation.")
    if not flags:
        flags.append("No severe allocation warning; still show pre- and post-allocation views to avoid distorted incentives.")

    return {"departments": results, "allocation_detail": allocation_detail, "cfo_flags": flags}


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Department P&L Allocation", ""]
    lines.append("| Department | Revenue | Direct costs | Pre-allocation margin | Allocated shared costs | Post-allocation margin |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for r in result["departments"]:
        lines.append(
            f"| {r['department']} | {r['revenue']:.2f} | {r['direct_costs']:.2f} | "
            f"{r['pre_allocation_margin']:.2f} | {r['allocated_shared_costs']:.2f} | {r['post_allocation_margin']:.2f} |"
        )
    lines.append("\n## CFO flags")
    for flag in result["cfo_flags"]:
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Allocate shared costs to departments.")
    parser.add_argument("input", type=Path, help="JSON allocation case")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
