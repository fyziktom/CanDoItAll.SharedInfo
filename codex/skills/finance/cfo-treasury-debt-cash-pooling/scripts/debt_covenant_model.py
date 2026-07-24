#!/usr/bin/env python3
"""Model debt metrics and covenant headroom."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def ratio(numerator: float, denominator: float) -> float | None:
    if denominator == 0:
        return None
    return numerator / denominator


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    ebitda = float(data.get("ebitda", 0))
    cash = float(data.get("cash", 0))
    debt_items: List[Dict[str, Any]] = data.get("debt", [])
    included_debt = [d for d in debt_items if d.get("covenant_included", True)]

    gross_debt = sum(float(d.get("principal", 0)) for d in included_debt)
    interest = sum(float(d.get("principal", 0)) * float(d.get("interest_rate", 0)) for d in included_debt)
    amortization = sum(float(d.get("annual_amortization", 0)) for d in included_debt)
    debt_service = interest + amortization
    net_debt = gross_debt - cash

    metrics = {
        "gross_debt": round(gross_debt, 2),
        "cash": round(cash, 2),
        "net_debt": round(net_debt, 2),
        "annual_interest": round(interest, 2),
        "annual_amortization": round(amortization, 2),
        "annual_debt_service": round(debt_service, 2),
        "net_debt_to_ebitda": None if ratio(net_debt, ebitda) is None else round(ratio(net_debt, ebitda), 4),
        "interest_cover": None if ratio(ebitda, interest) is None else round(ratio(ebitda, interest), 4),
        "debt_service_cover": None if ratio(ebitda, debt_service) is None else round(ratio(ebitda, debt_service), 4),
    }

    covenants = data.get("covenants", {}) or {}
    covenant_results = []
    if "max_net_debt_to_ebitda" in covenants and metrics["net_debt_to_ebitda"] is not None:
        limit = float(covenants["max_net_debt_to_ebitda"])
        actual = metrics["net_debt_to_ebitda"]
        covenant_results.append({
            "name": "max_net_debt_to_ebitda",
            "actual": actual,
            "limit": limit,
            "pass": actual <= limit,
            "headroom": round(limit - actual, 4),
        })
    if "min_interest_cover" in covenants and metrics["interest_cover"] is not None:
        limit = float(covenants["min_interest_cover"])
        actual = metrics["interest_cover"]
        covenant_results.append({
            "name": "min_interest_cover",
            "actual": actual,
            "limit": limit,
            "pass": actual >= limit,
            "headroom": round(actual - limit, 4),
        })
    if "min_debt_service_cover" in covenants and metrics["debt_service_cover"] is not None:
        limit = float(covenants["min_debt_service_cover"])
        actual = metrics["debt_service_cover"]
        covenant_results.append({
            "name": "min_debt_service_cover",
            "actual": actual,
            "limit": limit,
            "pass": actual >= limit,
            "headroom": round(actual - limit, 4),
        })

    flags = []
    for c in covenant_results:
        if not c["pass"]:
            flags.append(f"Covenant breach risk: {c['name']} actual {c['actual']} vs limit {c['limit']}.")
        elif abs(c["headroom"]) < 0.25:
            flags.append(f"Thin covenant headroom: {c['name']} headroom {c['headroom']}.")
    if net_debt > 0 and ebitda <= 0:
        flags.append("Positive net debt with non-positive EBITDA is a serious refinancing and covenant risk.")
    if not flags:
        flags.append("No covenant breach in simplified model; forecast headroom under downside scenarios.")

    return {"metrics": metrics, "covenants": covenant_results, "cfo_flags": flags}


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Debt and Covenant Analysis", "", "## Metrics"]
    for key, value in result["metrics"].items():
        lines.append(f"- {key.replace('_', ' ').title()}: {value}")
    lines.append("\n## Covenants")
    lines.append("| Covenant | Actual | Limit | Pass | Headroom |")
    lines.append("|---|---:|---:|---:|---:|")
    for c in result["covenants"]:
        lines.append(f"| {c['name']} | {c['actual']} | {c['limit']} | {c['pass']} | {c['headroom']} |")
    lines.append("\n## CFO flags")
    for flag in result["cfo_flags"]:
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Model debt covenants.")
    parser.add_argument("input", type=Path, help="JSON debt case")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
