---
name: cfo-cashflow-working-capital
description: Analyze cash-flow, liquidity, 13-week forecasts, runway, burn rate, working capital, DSO, DPO, DIO, cash conversion cycle, AR/AP/inventory, payment terms, collections, and cash discipline.
---

# Cash-flow and Working Capital Skill

## When to use

Use this skill when the user asks about cash-flow, liquidity, 13-week forecasts, runway, burn rate, working capital, AR collections, AP payment strategy, inventory cash lock-up, DSO/DPO/DIO, cash conversion cycle, overtrading, supplier pressure, customer payment terms, or short-term cash control.

## CFO principle

Cash-flow management is not only accounting. It is the daily control of the timing, certainty, and legal availability of cash. A company can be profitable and still fail when cash is trapped in receivables, inventory, slow billing, uncontrolled capex, tax payments, payroll, debt maturities, or group entities.

## Analysis workflow

1. Establish cash reality:
   - bank cash;
   - restricted cash;
   - trapped entity cash;
   - undrawn committed facilities;
   - immediate obligations;
   - payroll, tax, debt, supplier, and rent dates.
2. Build a direct 13-week cash forecast:
   - weekly inflows by source and probability;
   - weekly outflows by due date and flexibility;
   - minimum cash threshold;
   - downside scenario.
3. Diagnose working capital:
   - AR aging and DSO;
   - AP aging and DPO;
   - inventory aging and DIO;
   - cash conversion cycle;
   - billing delays and dispute causes.
4. Identify cash levers:
   - collect overdue AR;
   - accelerate billing;
   - restructure customer payment terms;
   - delay non-critical AP without destroying supply;
   - reduce slow-moving inventory;
   - pause discretionary spend;
   - use factoring/receivables financing if economics and control risk are acceptable;
   - negotiate credit lines or shareholder loans;
   - sell non-core assets.
5. Recommend governance:
   - weekly cash war room if liquidity is tight;
   - payment approval list;
   - AR owner and escalation path;
   - purchasing freeze or PO discipline;
   - daily bank reconciliation in crisis.

## Working capital interpretation

- Rising DSO means customers are financing themselves with company cash.
- Rising DIO means cash is tied in inventory and may hide obsolescence.
- Very high DPO may temporarily help cash but can create supplier risk and hidden operating fragility.
- Negative working capital can be excellent in some models, but dangerous if it depends on unstable customer prepayments or delayed obligations.
- Fast growth can consume cash even with strong margins when inventory, receivables, or implementation costs scale faster than collections.

## Output format

```markdown
# Cash-flow and Working Capital Review

## 1. Liquidity status
## 2. Forecast and runway
## 3. Working capital diagnosis
## 4. Cash levers
## 5. Risks and trade-offs
## 6. CFO recommendation
## 7. Immediate actions
```

## Script usage

For exact cash forecast calculations:

```bash
python scripts/cashflow_forecast.py assets/examples/cashflow_case.json --markdown
```

For working capital KPIs:

```bash
python scripts/working_capital_kpis.py assets/examples/working_capital_case.json --markdown
```

Use script results as a quantitative base, then add judgement about probability, stakeholder risk, and operational feasibility.

## References

Read `references/cashflow_playbook.md` and `references/working_capital_playbook.md`.
