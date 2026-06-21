---
name: flaky-test-hunter
description: Finds and diagnoses tests that pass unreliably due to timing, shared state, or external dependencies
tags: [testing, flaky, ci, reliability, debugging]
tools: Read, Grep, Glob, Bash
---

# Flaky Test Hunter

## When to Use
- CI passes locally but fails intermittently in the pipeline
- A test needs multiple retries to pass
- Test results differ between runs with no code changes
- Coverage numbers bounce up and down across CI runs
- A test passes in isolation but fails in the full suite

## How It Works

1. **Identify suspects** — grep for common flakiness patterns: `setTimeout`, `sleep`, `Date.now()`, `Math.random()`, `.toBeGreaterThan(0)` on timing values
2. **Check for shared state** — find tests that modify global variables, module-level singletons, or database state without cleanup
3. **Check for missing awaits** — async operations not awaited in test setup/teardown; missing `await` before assertions
4. **Check for time coupling** — assertions on `Date`, `new Date()`, or timestamp fields without mocking the clock
5. **Check for external dependencies** — HTTP calls, filesystem reads, or port bindings in unit tests
6. **Check test ordering** — tests that depend on execution order (no `beforeEach` reset, state leaking from previous test)
7. **Run N times** — if Bash available, run the suspect test file 5 times and report pass/fail pattern
8. **Output diagnosis** — each flaky test with root cause classification and fix

## Quick Start
```
/flaky-test-hunter
```
Target a specific test file:
```
/flaky-test-hunter src/services/__tests__/cache.test.ts
```

## Output Format
```
Flaky Test Hunt
===============
Test files scanned: 34

CONFIRMED FLAKY (failed in 2+ of 5 runs)
  src/api/__tests__/auth.test.ts — "login returns 200"
    Root cause: TIMING — uses setTimeout(200) to wait for async op
    Pattern: test/src/api/__tests__/auth.test.ts:34
      await new Promise(r => setTimeout(r, 200))
    Fix: mock the async operation with jest.useFakeTimers() or use waitFor()

  src/services/__tests__/cache.test.ts — "cache expires stale entries"
    Root cause: CLOCK DEPENDENCY — asserts on real Date.now()
    Pattern: expect(entry.expiresAt).toBeGreaterThan(Date.now())
    Fix: use jest.setSystemTime() to control the clock

SUSPECTED FLAKY (pattern detected, not confirmed)
  src/db/__tests__/user.test.ts
    Root cause: SHARED STATE — no afterEach cleanup of db.users table
    Pattern: tests insert rows but no transaction rollback or truncate
    Fix: wrap each test in a transaction and rollback in afterEach

  src/__tests__/integration/orders.test.ts
    Root cause: EXTERNAL DEPENDENCY — real HTTP call to payment gateway
    Pattern: fetch('https://api.stripe.com/...') in test body
    Fix: mock with jest.mock() or nock; use test API keys at minimum
```

## Common Root Cause Patterns
| Pattern | Root Cause | Fix |
|---------|-----------|-----|
| `setTimeout` in test | Timing | `jest.useFakeTimers()` |
| `new Date()` in assertion | Clock dependency | `jest.setSystemTime()` |
| Missing `await` | Async leak | Add `await`, check return type |
| No `afterEach` cleanup | Shared state | Reset DB, clear mocks, restore globals |
| Real HTTP in unit test | External dep | Mock the HTTP layer |
| Port binding (`listen(3000)`) | Resource conflict | Use port 0 for random port |

## Related Skills
- `coverage-gap-analyzer` — flaky tests inflate coverage numbers; fix flaky first
- `tdd-enforcer` — tests written TDD-style rarely become flaky
