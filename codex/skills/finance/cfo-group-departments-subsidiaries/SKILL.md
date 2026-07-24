---
name: cfo-group-departments-subsidiaries
description: Analyze group finance, departments, daughter companies, subsidiaries, shared services, cost allocation, intercompany balances, transfer pricing warnings, consolidation logic, and responsibility accounting.
---

# Group, Departments, and Subsidiaries Skill

## When to use

Use this skill when the task involves departments, cost centers, daughter companies, subsidiaries, holding structures, group reporting, intercompany transactions, shared service allocation, department profitability, legal entity boundaries, consolidation, or internal responsibility accounting.

## CFO principle

Departments and subsidiaries are not only boxes on an org chart. They are financial responsibility centers with incentives, decision rights, costs, capital needs, risks, and legal boundaries. A CFO must see both the management view and the legal entity view.

## Analysis workflow

1. Map the structure:
   - legal entities;
   - departments;
   - business units;
   - cost centers;
   - profit centers;
   - shared services;
   - management owners.
2. Decide the view required:
   - statutory entity reporting;
   - management reporting;
   - department P&L;
   - project/product P&L;
   - consolidated group view;
   - cash/legal entity view.
3. Allocate shared costs only when it improves decisions:
   - use clear drivers;
   - avoid arbitrary allocations that punish efficient departments;
   - separate controllable and non-controllable costs;
   - show both pre-allocation and post-allocation margin.
4. Intercompany analysis:
   - identify invoices, loans, royalties, management fees, cost recharges, and cash sweeps;
   - net balances where legal and operationally appropriate;
   - avoid hiding liquidity stress in intercompany balances;
   - warn about tax/transfer pricing review.
5. Subsidiary / daughter company governance:
   - local statutory obligations;
   - local cash needs;
   - board/signatory authority;
   - group delegation of authority;
   - minority shareholder or lender restrictions;
   - consolidation calendar.

## Allocation rules

Good allocation drivers should be:

- observable;
- hard to manipulate;
- relevant to cost causation;
- stable enough for planning;
- understandable to budget owners.

Common drivers:

- headcount for HR and office costs;
- revenue for sales enablement and customer success costs;
- transactions for finance operations;
- users/seats for IT systems;
- storage/compute for cloud costs;
- floor area for facilities;
- direct labor hours for production overhead.

## Output format

```markdown
# Group / Department Finance Review

## 1. Structure map
## 2. Management view vs legal entity view
## 3. Department/subsidiary economics
## 4. Shared cost allocation logic
## 5. Intercompany balances and cash impact
## 6. Governance and controls
## 7. CFO recommendation
```

## Script usage

```bash
python scripts/department_pnl_allocator.py assets/examples/department_allocation_case.json --markdown
python scripts/intercompany_netting.py assets/examples/intercompany_balances.csv --markdown
```

## References

Read `references/group_finance_playbook.md`.
