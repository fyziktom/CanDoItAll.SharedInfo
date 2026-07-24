---
name: cfo-turnaround-crisis-management
description: Handle financial distress, cash crisis, turnaround, covenant breach, supplier pressure, runway emergency, restructuring options, cash war room, and stakeholder communication.
---

# Turnaround and Crisis Financial Management Skill

## When to use

Use this skill when the company is in financial distress or might become distressed: cash shortage, payroll risk, supplier stop, covenant breach, debt default, liquidity crisis, insolvency concerns, emergency fundraising, severe burn, loss of customer confidence, or urgent restructuring.

## CFO principle

In distress, cash timing and stakeholder sequencing dominate. The CFO's first job is to preserve options, avoid uncontrolled promises, maintain reliable facts, and prevent a liquidity problem from becoming an operational collapse.

## Crisis triage workflow

1. Establish immediate survival facts:
   - cash today;
   - restricted cash;
   - payroll date;
   - tax due dates;
   - debt service dates;
   - critical supplier cutoff dates;
   - customer receipts certainty;
   - legal/insolvency thresholds;
   - available facilities;
   - board-approved actions.
2. Build a 13-week cash forecast and downside scenario.
3. Classify obligations:
   - must pay to operate safely/legally;
   - critical supplier / payroll / tax;
   - negotiable but sensitive;
   - deferrable;
   - disputed;
   - discretionary.
4. Create a cash war room:
   - daily bank reconciliation;
   - payment approval list;
   - AR collection owner;
   - supplier negotiation owner;
   - forecast owner;
   - stakeholder communication owner.
5. Preserve optionality:
   - stop discretionary spend;
   - pause unapproved hiring;
   - review capex;
   - negotiate payment plans;
   - sell non-core assets;
   - raise bridge financing;
   - restructure debt;
   - renegotiate customer terms;
   - review product/customer profitability.
6. Communicate carefully:
   - board first;
   - lenders early if covenant risk;
   - suppliers with credible payment plan;
   - employees with legal/HR review;
   - investors with clear milestones.

## Important warnings

- Do not give insolvency, tax, employment, securities, or legal advice. Recommend legal/restructuring professional review when obligations cannot be met when due.
- Do not recommend selective payments without considering legal and preference risks.
- Do not rely on speculative inflows for survival planning.
- Do not hide covenant issues from lenders until the breach occurs.
- Do not destroy supplier trust by making promises the company cannot keep.

## Output format

```markdown
# Financial Crisis / Turnaround Review

## 1. Crisis status
## 2. Immediate survival facts
## 3. 13-week cash view
## 4. Payment prioritization
## 5. Stakeholder strategy
## 6. Turnaround levers
## 7. Legal/professional review flags
## 8. Next 72 hours / 2 weeks / 13 weeks
```

## Script usage

Use scripts from other skills:

```bash
python ../cfo-cashflow-working-capital/scripts/cashflow_forecast.py ../cfo-cashflow-working-capital/assets/examples/cashflow_case.json --markdown
python ../cfo-treasury-debt-cash-pooling/scripts/debt_covenant_model.py ../cfo-treasury-debt-cash-pooling/assets/examples/debt_case.json --markdown
```

## References

Read `references/turnaround_playbook.md`.
