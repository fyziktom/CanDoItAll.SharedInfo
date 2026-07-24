---
name: cfo-reporting-kpis-board-pack
description: Prepare CFO reporting, monthly management accounts, KPI dashboards, board packs, variance analysis, unit economics, profitability views, and financial narrative.
---

# Reporting, KPIs, and Board Pack Skill

## When to use

Use this skill when the user asks for a CFO report, board pack, monthly management pack, KPI dashboard, variance analysis, financial narrative, unit economics summary, department reporting, or investor-ready finance update.

## CFO principle

A finance report should drive decisions, not just describe numbers. It must connect P&L, cash-flow, balance sheet, KPIs, risks, and actions into one coherent management narrative.

## Reporting workflow

1. Identify audience:
   - founder/CEO;
   - department manager;
   - board;
   - bank/lender;
   - investor;
   - operational team.
2. Select report cadence:
   - daily cash in crisis;
   - weekly cash / sales / AR;
   - monthly management pack;
   - quarterly board pack;
   - annual budget and strategic plan.
3. Build the finance narrative:
   - what changed;
   - why it changed;
   - whether it is temporary or structural;
   - cash impact;
   - management action;
   - decision required.
4. Include core statements:
   - P&L summary;
   - cash-flow / liquidity;
   - balance sheet / working capital;
   - debt/covenants;
   - KPI dashboard;
   - risk and externality highlights;
   - decisions and action log.
5. Validate KPI quality:
   - clear definition;
   - owner;
   - data source;
   - frequency;
   - target;
   - reconciliation to finance where relevant;
   - anti-gaming check.

## KPI patterns by company type

### Universal CFO KPIs

- revenue growth;
- gross margin;
- EBITDA;
- operating cash-flow;
- free cash-flow;
- cash runway;
- DSO, DPO, DIO, cash conversion cycle;
- net debt;
- covenant headroom;
- budget variance.

### SaaS

ARR/MRR, churn, net revenue retention, CAC payback, LTV/CAC, cloud gross margin, activation, expansion revenue.

### Manufacturing / hardware

SKU margin, inventory days, stockouts, yield, scrap, warranty, supplier concentration, purchase commitments.

### Services / projects

Utilization, realization, project margin, WIP, backlog, pipeline coverage, milestone collection.

## Output format

```markdown
# CFO Reporting Pack

## 1. Executive summary
## 2. P&L performance
## 3. Cash-flow and liquidity
## 4. Working capital and balance sheet
## 5. KPI dashboard
## 6. Risks, controls, and externalities
## 7. Decisions required
## 8. Action log
```

## Script usage

```bash
python scripts/kpi_dashboard_generator.py assets/examples/kpi_case.json --markdown
```

Use script output as a base dashboard and then add a CFO narrative.

## References

Read `references/reporting_pack_playbook.md` and use
`assets/monthly_cfo_brief_template.md`.
