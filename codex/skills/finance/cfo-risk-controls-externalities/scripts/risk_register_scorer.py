#!/usr/bin/env python3
"""Score a risk register using a simple residual-risk model."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any, Dict, List


def parse_bool(value: Any) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y"}


def load(path: Path) -> List[Dict[str, Any]]:
    if path.suffix.lower() == ".json":
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
        return data.get("risks", data if isinstance(data, list) else [])
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def analyze(rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    scored = []
    for row in rows:
        likelihood = float(row.get("likelihood", 0) or 0)
        impact = float(row.get("impact", 0) or 0)
        velocity = float(row.get("velocity", 3) or 3)
        control = float(row.get("control_effectiveness", 0) or 0)
        control = min(max(control, 0.0), 1.0)
        velocity_factor = 1 + max(0.0, velocity - 3) * 0.15
        externality_factor = 1.1 if parse_bool(row.get("externality", False)) else 1.0
        inherent = likelihood * impact * velocity_factor * externality_factor
        residual = inherent * (1 - control)
        scored.append({
            "risk": row.get("risk") or row.get("name") or "unknown",
            "category": row.get("category", "unknown"),
            "owner": row.get("owner", "unassigned"),
            "likelihood": likelihood,
            "impact": impact,
            "velocity": velocity,
            "control_effectiveness": control,
            "externality": parse_bool(row.get("externality", False)),
            "inherent_score": round(inherent, 2),
            "residual_score": round(residual, 2),
            "priority": "high" if residual >= 12 else "medium" if residual >= 6 else "low",
        })
    scored.sort(key=lambda x: x["residual_score"], reverse=True)
    flags = []
    high = [r for r in scored if r["priority"] == "high"]
    if high:
        flags.append(f"{len(high)} high residual risks require management attention and owner action plans.")
    unassigned = [r for r in scored if r["owner"] == "unassigned"]
    if unassigned:
        flags.append(f"{len(unassigned)} risks have no owner; assign accountability.")
    if not flags:
        flags.append("No high residual risks under this simplified scoring model; validate scoring calibration.")
    return {"risks": scored, "cfo_flags": flags}


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Risk Register Score", ""]
    lines.append("| Risk | Category | Owner | Inherent | Residual | Priority | Externality |")
    lines.append("|---|---|---|---:|---:|---|---:|")
    for r in result["risks"]:
        lines.append(f"| {r['risk']} | {r['category']} | {r['owner']} | {r['inherent_score']} | {r['residual_score']} | {r['priority']} | {r['externality']} |")
    lines.append("\n## CFO flags")
    for flag in result["cfo_flags"]:
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Score risk register.")
    parser.add_argument("input", type=Path, help="CSV or JSON risk register")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(load(args.input))
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
