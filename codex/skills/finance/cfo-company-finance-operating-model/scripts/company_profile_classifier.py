#!/usr/bin/env python3
"""Classify a company profile and recommend a finance operating model."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict, List


def load_json(path: Path) -> Dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def as_lower(value: Any) -> str:
    return str(value or "").strip().lower()


def classify(profile: Dict[str, Any]) -> Dict[str, Any]:
    industry = as_lower(profile.get("industry"))
    stage = as_lower(profile.get("stage"))
    revenue_model = as_lower(profile.get("revenue_model"))
    inventory = as_lower(profile.get("inventory_intensity"))
    capex = as_lower(profile.get("capex_intensity"))
    group = as_lower(profile.get("group_complexity"))
    regulated = bool(profile.get("regulated", False))

    archetypes: List[str] = []
    if "saas" in industry or "subscription" in revenue_model:
        archetypes.append("SaaS/subscription")
    if "hardware" in industry or inventory in {"medium", "high"}:
        archetypes.append("Product/hardware")
    if "manufact" in industry:
        archetypes.append("Manufacturing")
    if "project" in revenue_model or "construction" in industry:
        archetypes.append("Project business")
    if "service" in revenue_model or "consult" in industry:
        archetypes.append("Services")
    if "marketplace" in revenue_model:
        archetypes.append("Marketplace/platform")
    if capex == "high" or any(x in industry for x in ["energy", "infrastructure", "utility"]):
        archetypes.append("Asset-heavy/infrastructure")
    if group in {"medium", "high", "complex", "cross-border"}:
        archetypes.append("Group/holding")
    if regulated:
        archetypes.append("Regulated")
    if not archetypes:
        archetypes.append("General SME")

    dimensions = ["legal_entity", "department_cost_center"]
    kpis = ["cash runway", "monthly revenue", "gross margin", "EBITDA", "budget variance"]
    controls = ["bank reconciliation", "payment approval matrix", "monthly close checklist"]

    if "SaaS/subscription" in archetypes:
        dimensions.extend(["product", "customer_segment", "cohort"])
        kpis.extend(["ARR/MRR", "churn", "net revenue retention", "CAC payback", "cloud gross margin"])
    if "Product/hardware" in archetypes or "Manufacturing" in archetypes:
        dimensions.extend(["SKU", "warehouse", "supplier"])
        kpis.extend(["inventory days", "SKU gross margin", "warranty rate", "purchase commitments"])
        controls.extend(["inventory count", "purchase order approval", "supplier concentration review"])
    if "Project business" in archetypes or "Services" in archetypes:
        dimensions.extend(["project", "contract", "delivery_team"])
        kpis.extend(["project margin", "utilization", "WIP", "milestone billing", "realization rate"])
    if "Group/holding" in archetypes:
        dimensions.extend(["intercompany_counterparty", "cash_pool", "shared_service"])
        kpis.extend(["entity cash", "intercompany balances", "net debt", "cash pooling surplus/deficit"])
        controls.extend(["intercompany agreement register", "delegation of authority by entity"])
    if regulated:
        controls.extend(["compliance owner", "risk committee", "segregation of duties", "audit trail preservation"])

    cadence = "weekly cash review, monthly close, monthly management pack"
    if stage in {"startup", "distressed", "turnaround"}:
        cadence = "daily/weekly cash review, weekly management pack, monthly close"
    elif stage in {"scaleup"}:
        cadence = "weekly cash review, bi-weekly KPI review, monthly management pack, quarterly board pack"

    return {
        "archetypes": archetypes,
        "recommended_finance_dimensions": sorted(set(dimensions)),
        "priority_kpis": sorted(set(kpis)),
        "minimum_controls": sorted(set(controls)),
        "recommended_cadence": cadence,
        "first_90_days": [
            "Create finance fact pack and reporting calendar",
            "Implement cost center and budget owner structure",
            "Introduce weekly cash forecast and AR/AP aging review",
            "Define approval matrix and payment controls",
            "Build management KPI pack for the identified archetypes",
        ],
        "warnings": [
            "Treat tax, transfer pricing, statutory accounting, payroll, and regulated matters as professional-review topics.",
            "Do not overbuild ERP complexity before the operating dimensions are stable.",
        ],
    }


def to_markdown(result: Dict[str, Any]) -> str:
    lines = ["# Company Finance Operating Model Recommendation", ""]
    for key, title in [
        ("archetypes", "Archetypes"),
        ("recommended_finance_dimensions", "Recommended finance dimensions"),
        ("priority_kpis", "Priority KPIs"),
        ("minimum_controls", "Minimum controls"),
        ("first_90_days", "First 90 days"),
        ("warnings", "Warnings"),
    ]:
        lines.append(f"## {title}")
        for item in result.get(key, []):
            lines.append(f"- {item}")
        lines.append("")
    lines.append(f"## Recommended cadence\n\n{result.get('recommended_cadence', '')}\n")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Classify a company profile for CFO operating model design.")
    parser.add_argument("input", type=Path, help="JSON company profile")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    profile = load_json(args.input)
    result = classify(profile)
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
