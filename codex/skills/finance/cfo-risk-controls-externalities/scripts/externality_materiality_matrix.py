#!/usr/bin/env python3
"""Score externalities by stakeholder and financial materiality."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def quadrant(stakeholder: float, financial: float) -> str:
    if stakeholder >= 4 and financial >= 4:
        return "double-material priority"
    if financial >= 4:
        return "financial-material priority"
    if stakeholder >= 4:
        return "impact-material priority"
    return "monitor"


def analyze(data: Dict[str, Any]) -> Dict[str, Any]:
    rows = []
    for item in data.get("externalities", []):
        stakeholder = float(item.get("stakeholder_impact", 0))
        financial = float(item.get("financial_impact", 0))
        probability = float(item.get("probability", 0))
        horizon = float(item.get("time_horizon", 3))
        controllability = float(item.get("controllability", 3))
        urgency_factor = 1 + max(0.0, 3 - horizon) * 0.15
        control_gap = 1 + max(0.0, 3 - controllability) * 0.1
        score = (stakeholder + financial) * probability * urgency_factor * control_gap
        rows.append({
            "name": item.get("name", "unknown"),
            "stakeholder_impact": stakeholder,
            "financial_impact": financial,
            "probability": probability,
            "time_horizon": horizon,
            "controllability": controllability,
            "score": round(score, 2),
            "quadrant": quadrant(stakeholder, financial),
        })
    rows.sort(key=lambda x: x["score"], reverse=True)
    flags = []
    for r in rows[:3]:
        if r["quadrant"] != "monitor":
            flags.append(f"{r['name']} is a {r['quadrant']} and should be connected to budget/risk owners.")
    if not flags:
        flags.append("No high materiality externality in simplified scoring; continue monitoring.")
    return {"externalities": rows, "cfo_flags": flags}


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Externality Materiality Matrix", ""]
    lines.append("| Externality | Stakeholder impact | Financial impact | Probability | Score | Quadrant |")
    lines.append("|---|---:|---:|---:|---:|---|")
    for r in result["externalities"]:
        lines.append(f"| {r['name']} | {r['stakeholder_impact']} | {r['financial_impact']} | {r['probability']} | {r['score']} | {r['quadrant']} |")
    lines.append("\n## CFO flags")
    for flag in result["cfo_flags"]:
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Score externality materiality.")
    parser.add_argument("input", type=Path, help="JSON externalities case")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load_json(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
