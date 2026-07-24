#!/usr/bin/env python3
"""Analyze a direct weekly cash-flow forecast."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any, Dict, List


def load_input(path: Path, starting_cash: float | None, minimum_cash: float | None) -> Dict[str, Any]:
    if path.suffix.lower() == ".json":
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)

    weeks: List[Dict[str, Any]] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            weeks.append({
                "week": row.get("week") or row.get("date") or f"week-{len(weeks)+1}",
                "inflows": float(row.get("inflows", 0) or 0),
                "outflows": float(row.get("outflows", 0) or 0),
                "notes": row.get("notes", ""),
            })
    if starting_cash is None:
        raise ValueError("--starting-cash is required for CSV input")
    return {"starting_cash": starting_cash, "minimum_cash": minimum_cash or 0, "weeks": weeks}


def analyze(data: Dict[str, Any], inflow_multiplier: float, outflow_multiplier: float) -> Dict[str, Any]:
    starting_cash = float(data.get("starting_cash", 0))
    minimum_cash = float(data.get("minimum_cash", 0))
    restricted_cash = float(data.get("restricted_cash", 0))
    undrawn_facilities = float(data.get("undrawn_facilities", 0))
    available_starting_cash = starting_cash - restricted_cash

    closing = available_starting_cash
    rows: List[Dict[str, Any]] = []
    first_breach = None
    first_negative = None
    total_inflows = 0.0
    total_outflows = 0.0

    for index, week in enumerate(data.get("weeks", []), start=1):
        inflows = float(week.get("inflows", 0)) * inflow_multiplier
        outflows = float(week.get("outflows", 0)) * outflow_multiplier
        opening = closing
        net = inflows - outflows
        closing = opening + net
        total_inflows += inflows
        total_outflows += outflows
        row = {
            "week_index": index,
            "week": week.get("week", f"week-{index}"),
            "opening_cash": round(opening, 2),
            "inflows": round(inflows, 2),
            "outflows": round(outflows, 2),
            "net_flow": round(net, 2),
            "closing_cash": round(closing, 2),
            "below_minimum": closing < minimum_cash,
            "negative_cash": closing < 0,
            "notes": week.get("notes", ""),
        }
        if first_breach is None and closing < minimum_cash:
            first_breach = row["week"]
        if first_negative is None and closing < 0:
            first_negative = row["week"]
        rows.append(row)

    weekly_net_flows = [r["net_flow"] for r in rows]
    burn_weeks = [abs(x) for x in weekly_net_flows if x < 0]
    average_burn = sum(burn_weeks) / len(burn_weeks) if burn_weeks else 0.0
    runway_weeks = None
    if average_burn > 0:
        runway_weeks = max(0.0, (available_starting_cash + undrawn_facilities - minimum_cash) / average_burn)

    lowest_cash = min([available_starting_cash] + [r["closing_cash"] for r in rows]) if rows else available_starting_cash
    return {
        "starting_cash": starting_cash,
        "restricted_cash": restricted_cash,
        "available_starting_cash": round(available_starting_cash, 2),
        "minimum_cash": minimum_cash,
        "undrawn_facilities": undrawn_facilities,
        "total_inflows": round(total_inflows, 2),
        "total_outflows": round(total_outflows, 2),
        "ending_cash": round(closing, 2),
        "lowest_cash": round(lowest_cash, 2),
        "average_negative_weekly_burn": round(average_burn, 2),
        "estimated_runway_weeks_after_minimum": None if runway_weeks is None else round(runway_weeks, 2),
        "first_minimum_cash_breach_week": first_breach,
        "first_negative_cash_week": first_negative,
        "rows": rows,
        "cfo_flags": build_flags(first_breach, first_negative, lowest_cash, minimum_cash, average_burn),
    }


def build_flags(first_breach: str | None, first_negative: str | None, lowest_cash: float, minimum_cash: float, average_burn: float) -> List[str]:
    flags: List[str] = []
    if first_negative:
        flags.append(f"Cash becomes negative in {first_negative}; immediate financing or payment deferral is required.")
    elif first_breach:
        flags.append(f"Cash falls below the minimum threshold in {first_breach}; activate liquidity controls.")
    if lowest_cash < minimum_cash * 1.25:
        flags.append("Liquidity buffer is thin; downside scenario should be modeled.")
    if average_burn > 0:
        flags.append("Company has negative cash-flow weeks; separate structural burn from timing issues.")
    if not flags:
        flags.append("No immediate minimum-cash breach in the provided forecast, but validate inflow certainty.")
    return flags


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Cash-flow Forecast Analysis", ""]
    summary_keys = [
        "available_starting_cash", "minimum_cash", "undrawn_facilities", "total_inflows", "total_outflows",
        "ending_cash", "lowest_cash", "average_negative_weekly_burn", "estimated_runway_weeks_after_minimum",
        "first_minimum_cash_breach_week", "first_negative_cash_week",
    ]
    lines.append("## Summary")
    for key in summary_keys:
        lines.append(f"- {key.replace('_', ' ').title()}: {result.get(key)}")
    lines.append("\n## CFO flags")
    for flag in result.get("cfo_flags", []):
        lines.append(f"- {flag}")
    lines.append("\n## Weekly forecast")
    lines.append("| Week | Opening | Inflows | Outflows | Net | Closing | Flag |")
    lines.append("|---|---:|---:|---:|---:|---:|---|")
    for row in result.get("rows", []):
        flag = "negative" if row["negative_cash"] else "below minimum" if row["below_minimum"] else "ok"
        lines.append(
            f"| {row['week']} | {row['opening_cash']:.2f} | {row['inflows']:.2f} | {row['outflows']:.2f} | "
            f"{row['net_flow']:.2f} | {row['closing_cash']:.2f} | {flag} |"
        )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Analyze weekly cash-flow forecast data.")
    parser.add_argument("input", type=Path, help="JSON or CSV forecast input")
    parser.add_argument("--starting-cash", type=float, help="Starting cash for CSV input")
    parser.add_argument("--minimum-cash", type=float, help="Minimum cash threshold for CSV input")
    parser.add_argument("--inflow-multiplier", type=float, default=1.0, help="Scenario multiplier for inflows")
    parser.add_argument("--outflow-multiplier", type=float, default=1.0, help="Scenario multiplier for outflows")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    data = load_input(args.input, args.starting_cash, args.minimum_cash)
    result = analyze(data, args.inflow_multiplier, args.outflow_multiplier)
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
