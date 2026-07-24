#!/usr/bin/env python3
"""Calculate working capital KPIs and target cash release."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict


def safe_div(numerator: float, denominator: float) -> float | None:
    if denominator == 0:
        return None
    return numerator / denominator


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    days = float(data.get("period_days", 365))
    revenue = float(data.get("revenue", 0))
    cogs = float(data.get("cogs", 0))
    ar = float(data.get("accounts_receivable", 0))
    inventory = float(data.get("inventory", 0))
    ap = float(data.get("accounts_payable", 0))
    targets = data.get("targets", {}) or {}

    dso = safe_div(ar, revenue)
    dio = safe_div(inventory, cogs)
    dpo = safe_div(ap, cogs)
    dso_days = None if dso is None else dso * days
    dio_days = None if dio is None else dio * days
    dpo_days = None if dpo is None else dpo * days
    ccc = None
    if dso_days is not None and dio_days is not None and dpo_days is not None:
        ccc = dso_days + dio_days - dpo_days

    target_cash = {}
    if "dso" in targets and revenue:
        target_ar = revenue * float(targets["dso"]) / days
        target_cash["ar_cash_release_if_target_dso"] = round(max(0, ar - target_ar), 2)
    if "dio" in targets and cogs:
        target_inventory = cogs * float(targets["dio"]) / days
        target_cash["inventory_cash_release_if_target_dio"] = round(max(0, inventory - target_inventory), 2)
    if "dpo" in targets and cogs:
        target_ap = cogs * float(targets["dpo"]) / days
        target_cash["additional_supplier_financing_if_target_dpo"] = round(max(0, target_ap - ap), 2)

    flags = []
    if dso_days is not None and dso_days > 60:
        flags.append("DSO is high; prioritize AR aging, dispute resolution, and collection ownership.")
    if dio_days is not None and dio_days > 90:
        flags.append("DIO is high; review slow-moving stock, MOQ commitments, and forecast accuracy.")
    if dpo_days is not None and dpo_days > 90:
        flags.append("DPO is high; supplier relationship and supply continuity risk may be rising.")
    if ccc is not None and ccc > 90:
        flags.append("Cash conversion cycle is long; growth may consume substantial cash.")
    if not flags:
        flags.append("No severe working-capital warning from default thresholds; compare against industry norms.")

    return {
        "dso_days": None if dso_days is None else round(dso_days, 2),
        "dio_days": None if dio_days is None else round(dio_days, 2),
        "dpo_days": None if dpo_days is None else round(dpo_days, 2),
        "cash_conversion_cycle_days": None if ccc is None else round(ccc, 2),
        "net_working_capital": round(ar + inventory - ap, 2),
        "target_cash_effects": target_cash,
        "cfo_flags": flags,
    }


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Working Capital KPI Analysis", ""]
    for key in ["dso_days", "dio_days", "dpo_days", "cash_conversion_cycle_days", "net_working_capital"]:
        lines.append(f"- {key.replace('_', ' ').title()}: {result.get(key)}")
    lines.append("\n## Target cash effects")
    for key, value in result.get("target_cash_effects", {}).items():
        lines.append(f"- {key.replace('_', ' ').title()}: {value}")
    lines.append("\n## CFO flags")
    for flag in result.get("cfo_flags", []):
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Calculate working capital KPIs.")
    parser.add_argument("input", type=Path, help="JSON input")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
