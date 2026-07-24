---
name: cfo-treasury-debt-cash-pooling
description: Analyze treasury, debt, bank loans, covenants, liquidity facilities, interest cost, cash pooling, group cash, intercompany loans, FX exposure, and lender communication.
---

# Treasury, Debt, and Cash Pooling Skill

## When to use

Use this skill for bank debt, loans, covenants, interest expense, refinancing, liquidity facilities, cash pooling, group treasury, intercompany loans, surplus cash in subsidiaries, overdrafts, FX exposure, trapped cash, lender communication, and treasury policy.

## CFO principle

Treasury controls the company's financial oxygen. The CFO must know where cash legally sits, who can move it, what debt conditions apply, and which obligations can trigger a liquidity or covenant crisis.

## Treasury analysis workflow

1. Map cash by legal entity, bank, currency, restriction, and operational need.
2. Map debt by borrower, lender, facility, interest rate, maturity, amortization, security, and covenant.
3. Identify group liquidity:
   - surplus cash;
   - deficits/overdrafts;
   - trapped cash;
   - minimum local cash;
   - tax/legal restrictions;
   - currency risk.
4. Analyze covenants:
   - net debt / EBITDA;
   - interest cover;
   - debt service cover;
   - minimum liquidity;
   - borrowing base;
   - reporting deadlines.
5. Evaluate cash pooling options:
   - physical zero balancing;
   - target balancing;
   - notional pooling;
   - intercompany loans;
   - dividend/return of capital;
   - local credit lines.
6. Consider restrictions:
   - tax and transfer pricing;
   - thin capitalization / interest deductibility;
   - withholding tax;
   - minority shareholders;
   - regulated entities;
   - lender negative pledges and restricted payments;
   - currency controls.
7. Recommend governance:
   - treasury policy;
   - bank mandate authority;
   - payment signatories;
   - intercompany agreement register;
   - covenant forecast calendar;
   - FX policy.

## Cash pooling rules of thumb

- Cash pooling is not just moving cash. It is a legal, tax, banking, and governance design.
- Physical pooling gives clear cash movement but creates intercompany balances.
- Notional pooling may reduce interest without legal movement but depends on bank setup and local rules.
- Intercompany loans need documented terms, maturity, interest, currency, repayment ability, and tax support.
- Never assume cash in a subsidiary is freely available to the parent.

## Output format

```markdown
# Treasury / Debt / Cash Pooling Review

## 1. Cash and debt map
## 2. Liquidity and covenant position
## 3. Cash pooling / intercompany options
## 4. Risks and restrictions
## 5. Treasury controls
## 6. CFO recommendation
```

## Script usage

```bash
python scripts/debt_covenant_model.py assets/examples/debt_case.json --markdown
python scripts/cash_pool_optimizer.py assets/examples/cash_pool_case.json --markdown
```

Use script results as a simplified model; add tax/legal/bank documentation warnings where relevant.

## References

Read `references/treasury_policy_playbook.md` and `references/cash_pooling_playbook.md`.
