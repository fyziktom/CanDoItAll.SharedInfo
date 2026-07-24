---
name: cfo-capital-allocation-investments
description: Evaluate capital allocation, investments, CapEx, acquisitions, R&D, AI infrastructure, NPV, IRR, payback, sensitivity, hurdle rates, portfolio prioritization, and investment governance.
---

# Capital Allocation and Investment Skill

## When to use

Use this skill for investment decisions: CapEx, R&D spend, hiring, marketing scale-up, acquisitions, product development, manufacturing equipment, AI/GPU infrastructure, cloud commitments, expansion, daughter company funding, or project portfolio prioritization.

## CFO principle

Capital allocation is the conversion of scarce cash, debt capacity, management attention, and risk capacity into future value. A project can have a positive NPV and still be rejected if it damages liquidity, violates covenants, creates excessive execution risk, or blocks a better strategic option.

## Investment workflow

1. Define the decision:
   - approve, reject, defer, stage-gate, lease instead of buy, partner, outsource, or run pilot.
2. Identify investment type:
   - maintenance CapEx;
   - growth CapEx;
   - R&D / product development;
   - automation;
   - acquisition;
   - market expansion;
   - regulatory/compliance;
   - risk reduction;
   - strategic option.
3. Build base-case economics:
   - initial cash outflow;
   - operating cash flows;
   - working capital impact;
   - maintenance cost;
   - tax/depreciation if relevant;
   - terminal value or salvage value;
   - financing cost and liquidity impact.
4. Calculate:
   - NPV;
   - IRR;
   - payback;
   - discounted payback;
   - sensitivity to revenue, margin, timing, capex overrun, and delay.
5. Add CFO judgement:
   - strategic fit;
   - option value;
   - reversibility;
   - capacity constraints;
   - key person / supplier risk;
   - regulatory or externality impact;
   - impact on covenants and cash runway.
6. Define governance:
   - owner;
   - milestones;
   - stage gates;
   - kill criteria;
   - post-investment review.

## Hurdle-rate guidance

Do not mechanically use one rate for everything. A maintenance investment with low execution risk is not the same as a speculative product bet. If no company hurdle rates are provided, state assumptions and use sensitivity rather than pretending certainty.

## Output format

```markdown
# Investment Case Review

## 1. Decision and investment type
## 2. Base-case economics
## 3. NPV / IRR / payback
## 4. Sensitivities and downside case
## 5. Strategic and liquidity assessment
## 6. Governance and stage gates
## 7. CFO recommendation
```

## Script usage

```bash
python scripts/investment_appraisal.py assets/examples/investment_case.json --markdown
```

Use script output for the numerical part and then interpret the business decision.

## References

Read `references/capital_allocation_playbook.md`.
