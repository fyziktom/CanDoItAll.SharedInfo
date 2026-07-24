---
name: cfo-company-finance-operating-model
description: Design finance operating models for different company types, stages, departments, cost centers, budgets, approval workflows, finance systems, and CFO governance.
---

# Company Finance Operating Model Skill

## When to use

Use this skill when the task is about how a company should organize finance: chart of accounts, cost centers, departments, budgeting, approval limits, finance team roles, ERP/reporting setup, profitability views, finance controls, and management cadence.

This skill is especially useful for small-to-large company design, scaleup readiness, investor readiness, ERP planning, company transformation, and adding finance discipline to a product, services, manufacturing, SaaS, hardware, IoT, energy, or project business.

## CFO operating model design workflow

1. Classify the company type and stage.
2. Identify the dominant economic engine:
   - recurring subscription revenue;
   - one-time product sales;
   - project delivery;
   - manufacturing throughput;
   - marketplace take-rate;
   - asset/infrastructure utilization;
   - regulated financial margin;
   - mixed model.
3. Decide which financial dimensions are required:
   - legal entity;
   - department / cost center;
   - product line;
   - project / contract;
   - customer segment;
   - geography;
   - channel;
   - funding source;
   - grant / restricted fund.
4. Design the minimum viable finance stack:
   - chart of accounts;
   - cost center hierarchy;
   - budget owner model;
   - approval matrix;
   - procurement and payment controls;
   - billing and collections process;
   - monthly close calendar;
   - management reporting pack;
   - cash forecast process;
   - data ownership.
5. Scale the design based on company maturity.

## Company archetypes and finance priorities

### Startup

Primary risk: runway and product-market fit. Finance should be simple but disciplined: cash runway, burn rate, hiring plan, founder approvals, investor-ready monthly metrics, and basic controls around payments and payroll.

### SaaS / subscription

Primary lens: ARR/MRR, churn, net revenue retention, CAC payback, customer acquisition efficiency, cloud gross margin, support cost, R&D capitalization policy if relevant, and deferred revenue.

### Hardware / manufacturing / IoT

Primary lens: bill of materials, inventory, production yield, warranty, supply-chain risk, DIO, purchase commitments, gross margin by SKU, product lifecycle, certifications, and channel terms.

### Services / consulting

Primary lens: utilization, billable rate, project margin, work-in-progress, revenue recognition, pipeline conversion, subcontractors, and cash collection milestones.

### Project / construction / long contract

Primary lens: contract margin, change orders, milestone billing, retention, WIP, performance bonds, claims, working capital, and project risk provisions.

### Marketplace / platform

Primary lens: GMV versus revenue, take-rate, payment timing, refunds, fraud, incentives/subsidies, network effects, customer concentration, and unit economics.

### Energy / infrastructure / asset-heavy

Primary lens: asset utilization, maintenance capex, regulatory pricing, project finance, debt service coverage, long-term contracts, externalities, permitting, and scenario risk.

### Corporate group

Primary lens: consolidation, legal entity cash, transfer pricing, intercompany loans, cash pooling, shared services, governance, capital allocation, and board reporting.

## Approval matrix pattern

Design approvals by risk, not by bureaucracy:

| Decision | Small company | Scaleup | Corporate group |
|---|---|---|---|
| Purchase order | Budget owner + finance check | Budget owner + department head + finance | Delegated authority matrix |
| New hire | Founder / CEO | Department head + CFO budget check | Workforce plan + HR + finance |
| CapEx | CEO/CFO | Investment committee above threshold | Board approval above threshold |
| Contract discount | Sales lead + CEO | Revenue ops + finance margin check | Deal desk |
| Bank debt | CEO/CFO | Board | Board + lender covenant review |

## Output format

Return:

1. Company finance classification.
2. Recommended finance dimensions and chart-of-accounts structure.
3. Department / cost center model.
4. Budgeting and approval model.
5. Reporting cadence.
6. Controls by maturity level.
7. Systems / data model recommendations.
8. Implementation roadmap: 30 / 60 / 90 days, then 12 months.

## Script usage

When the user gives a company profile in JSON, run:

```bash
python scripts/company_profile_classifier.py assets/examples/company_profile.json --markdown
```

Use the output as a structured starting point, then apply CFO judgement.

## References

Use `references/company_archetypes.md` and `references/finance_operating_model_checklist.md`.
