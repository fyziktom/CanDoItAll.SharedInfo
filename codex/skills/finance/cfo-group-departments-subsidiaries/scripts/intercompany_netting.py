#!/usr/bin/env python3
"""Net intercompany balances by currency and counterparty pair."""

from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict
from pathlib import Path
from typing import Dict, Tuple


def analyze(path: Path) -> Dict[str, object]:
    pair_balances: Dict[Tuple[str, str, str], float] = defaultdict(float)
    totals_by_entity_currency: Dict[Tuple[str, str], float] = defaultdict(float)
    rows = []

    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            from_entity = row["from_entity"].strip()
            to_entity = row["to_entity"].strip()
            currency = row.get("currency", "EUR").strip().upper()
            amount = float(row.get("amount", 0) or 0)
            key_entities = tuple(sorted([from_entity, to_entity]))
            sign = 1 if from_entity == key_entities[0] else -1
            pair_balances[(key_entities[0], key_entities[1], currency)] += sign * amount
            totals_by_entity_currency[(from_entity, currency)] -= amount
            totals_by_entity_currency[(to_entity, currency)] += amount
            rows.append(row)

    settlements = []
    for (a, b, currency), net in pair_balances.items():
        if abs(net) < 1e-9:
            continue
        if net > 0:
            settlements.append({"payer": b, "receiver": a, "currency": currency, "amount": round(abs(net), 2)})
        else:
            settlements.append({"payer": a, "receiver": b, "currency": currency, "amount": round(abs(net), 2)})

    entity_positions = [
        {"entity": entity, "currency": currency, "net_receivable_positive": round(value, 2)}
        for (entity, currency), value in sorted(totals_by_entity_currency.items())
    ]

    flags = [
        "Netting simplifies settlement but does not remove the need for legal, tax, transfer pricing, and intercompany documentation review.",
        "Separate loan balances from trade recharges before formal settlement.",
    ]
    return {"input_rows": len(rows), "settlements": settlements, "entity_positions": entity_positions, "cfo_flags": flags}


def to_markdown(result: Dict[str, object]) -> str:
    lines = ["# Intercompany Netting Analysis", ""]
    lines.append("## Settlement instructions")
    lines.append("| Payer | Receiver | Currency | Amount |")
    lines.append("|---|---|---|---:|")
    for s in result["settlements"]:  # type: ignore[index]
        lines.append(f"| {s['payer']} | {s['receiver']} | {s['currency']} | {s['amount']:.2f} |")
    lines.append("\n## Entity positions")
    lines.append("| Entity | Currency | Net receivable positive |")
    lines.append("|---|---|---:|")
    for p in result["entity_positions"]:  # type: ignore[index]
        lines.append(f"| {p['entity']} | {p['currency']} | {p['net_receivable_positive']:.2f} |")
    lines.append("\n## CFO flags")
    for flag in result["cfo_flags"]:  # type: ignore[index]
        lines.append(f"- {flag}")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Net intercompany balances from CSV.")
    parser.add_argument("input", type=Path, help="CSV with from_entity,to_entity,currency,amount")
    parser.add_argument("--markdown", action="store_true", help="Print Markdown instead of JSON")
    args = parser.parse_args()

    result = analyze(args.input)
    if args.markdown:
        print(to_markdown(result))
    else:
        print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
