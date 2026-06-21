---
name: coverage-gap-analyzer
description: Identifies untested code paths, missing edge cases, and coverage gaps in a targeted module or diff
tags: [testing, coverage, quality, tdd]
tools: Read, Grep, Glob, Bash
---

# Coverage Gap Analyzer

## When to Use
- After implementing a feature — before marking it done
- When coverage drops below the team threshold (80%)
- When auditing a module that's been flagged as risky
- Before adding tests to legacy code — find the highest-value gaps first

## How It Works

1. **Run existing coverage** — execute `jest --coverage`, `pytest --cov`, or `go test -cover` and parse the output
2. **Parse uncovered lines** — extract files and line ranges with 0% coverage
3. **Classify gaps** — distinguish: happy path missing, error path missing, edge case missing, integration path missing
4. **Prioritize by risk** — weight gaps by: is this code on the critical path? does it touch external systems? does it handle money or auth?
5. **Generate test stubs** — for each gap, write a failing test stub with the right describe/it structure and a comment on what to assert
6. **Output** — ranked gap list with generated stubs ready to fill in

## Quick Start
```
/coverage-gap-analyzer
```
Target a specific module:
```
/coverage-gap-analyzer src/services/payments/
```

## Output Format
```
Coverage Gap Analysis
=====================
Module: src/services/payments/
Overall coverage: 61% (target: 80%)

HIGH PRIORITY GAPS (critical path, no test)
  src/services/payments/processor.ts
    Lines 44-67: refund() function — zero coverage
    Lines 89-102: retry logic after gateway timeout — zero coverage
    Edge cases missing: amount = 0, currency mismatch, duplicate idempotency key

  Generated stub:
  describe('refund()', () => {
    it('processes a valid refund and returns confirmation id', async () => {
      // Arrange: create completed charge, valid refund amount
      // Act: call refund(chargeId, amount)
      // Assert: returns { refundId, status: 'succeeded' }
    })
    it('throws on refund amount exceeding original charge', async () => { /* TODO */ })
    it('retries on gateway timeout up to 3 times', async () => { /* TODO */ })
  })

MEDIUM PRIORITY GAPS
  src/services/payments/webhook.ts
    Lines 23-31: signature verification failure path — no test
    Missing: test for replayed webhooks (duplicate event id)

LOW PRIORITY GAPS
  src/services/payments/formatters.ts
    Lines 8-12: currency formatting for JPY (no decimal) — no test
```

## What Gets Generated
- Failing test stubs with correct `describe`/`it`/`test` structure for the detected framework
- Arrange/Act/Assert comment scaffolding inside each stub
- Mock/fixture hints where external deps are involved

## Related Skills
- `tdd-enforcer` — use before writing code to prevent gaps from forming
- `flaky-test-hunter` — find tests that pass unreliably and inflate reported coverage
