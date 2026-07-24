#!/usr/bin/env python3
"""Generate a compact CFO KPI dashboard from JSON input."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def ratio(n: float, d: float) -> float | None:
    if d == 0:
        return None
    return n / d


def pct(value: float | None) -> str:
    if value is None:
        return "n/a"
    return f"{value:.2%}"


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    revenue = float(data.get("revenue", 0))
    prior_revenue = float(data.get("prior_revenue", 0))
    budget_revenue = float(data.get("budget_revenue", 0))
    cogs = float(data.get("cogs", 0))
    opex = float(data.get("opex", 0))
    cash = float(data.get("cash", 0))
    restricted_cash = float(data.get("restricted_cash", 0))
    debt = float(data.get("debt", 0))
    ar = float(data.get("accounts_receivable", 0))
    inventory = float(data.get("inventory", 0))
    ap = float(data.get("accounts_payable", 0))
    days = float(data.get("period_days", 30))
    annual_revenue = float(data.get("annualized_revenue", revenue * 12))
    annual_cogs = float(data.get("annualized_cogs", cogs * 12))

    gross_profit = revenue - cogs
    ebitda = gross_profit - opex
    available_cash = cash - restricted_cash
    net_debt = debt - available_cash

    dso = ratio(ar, annual_revenue)
    dio = ratio(inventory, annual_cogs)
    dpo = ratio(ap, annual_cogs)
    dso_days = None if dso is None else dso * 365
    dio_days = None if dio is None else dio * 365
    dpo_days = None if dpo is None else dpo * 365

    churn = None
    customers = float(data.get("customers", 0))
    lost_customers = float(data.get("lost_customers", 0))
    if customers:
        churn = lost_customers / customers

    metrics = {
        "period": data.get("period", "unknown"),
        "revenue": round(revenue, 2),
        "revenue_growth_vs_prior": None if ratio(revenue - prior_revenue, prior_revenue) is None else round(ratio(revenue - prior_revenue, prior_revenue), 4),
        "revenue_vs_budget": None if ratio(revenue - budget_revenue, budget_revenue) is None else round(ratio(revenue - budget_revenue, budget_revenue), 4),
        "gross_margin": None if ratio(gross_profit, revenue) is None else round(ratio(gross_profit, revenue), 4),
        "ebitda": round(ebitda, 2),
        "ebitda_margin": None if ratio(ebitda, revenue) is None else round(ratio(ebitda, revenue), 4),
        "available_cash": round(available_cash, 2),
        "net_debt": round(net_debt, 2),
        "dso_days": None if dso_days is None else round(dso_days, 2),
        "dio_days": None if dio_days is None else round(dio_days, 2),
        "dpo_days": None if dpo_days is None else round(dpo_days, 2),
        "customer_churn": None if churn is None else round(churn, 4),
    }

    flags = []
    gm_target = data.get("gross_margin_target")
    if gm_target is not None and metrics["gross_margin"] is not None and metrics["gross_margin"] < float(gm_target):
        flags.append("Gross margin is below target; review pricing, COGS, mix, and delivery efficiency.")
    ebitda_target = data.get("ebitda_target")
    if ebitda_target is not None and ebitda < float(ebitda_target):
        flags.append("EBITDA is below target; separate revenue shortfall from cost overrun.")
    if metrics["revenue_vs_budget"] is not None and metrics["revenue_vs_budget"] < -0.05:
        flags.append("Revenue is more than 5% below budget; update forecast and cash plan.")
    if available_cash < 0:
        flags.append("Restricted cash exceeds cash balance in model; verify data.")
    if not flags:
        flags.append("No major default KPI warning; add business-specific thresholds.")

    return {"metrics": metrics, "cfo_flags": flags}


def to_markdown(result: Dict[str, Any]) -> str:
    metrics = result["metrics"]
    lines = [f"# CFO KPI Dashboard: {metrics.get('period')}", ""]
    lines.append("| KPI | Value |")
    lines.append("|---|---:|")
    for key, value in metrics.items():
        if key == "period":
            continue
        display = pct(value) if key.endswith(("margin", "budget", "prior", "churn")) and value is not None else value
        lines.append(f"| {key.replace('_', ' ').title()} | {display} |")
    lines.append("\n## CFO flags")
    for flag in result["cfo_flags"]:
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate CFO KPI dashboard.")
    parser.add_argument("input", type=Path, help="JSON KPI case")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
