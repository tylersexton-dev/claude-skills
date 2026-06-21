---
name: tdd-enforcer
description: Enforces red-green-refactor TDD cycle — writes failing tests first, then drives implementation to make them pass
tags: [testing, tdd, quality, workflow]
tools: Read, Grep, Glob, Bash, Write, Edit
---

# TDD Enforcer

## When to Use
- Starting any new feature, function, or module
- Fixing a bug (write a test that reproduces it first)
- Refactoring — establish a test harness before touching code
- Onboarding to a codebase — write tests to understand behavior before changing it

## How It Works

1. **Understand the contract** — read the task description and identify: inputs, outputs, side effects, error conditions
2. **Write failing tests first** — create the test file before the implementation file exists. Tests must fail with "not implemented" or "cannot find module"
3. **Verify RED** — run the test suite and confirm all new tests fail for the right reason (not a syntax error — a missing implementation)
4. **Write minimal implementation** — only enough code to make the failing tests pass. No extra features.
5. **Verify GREEN** — run tests, confirm they pass
6. **Refactor** — clean up implementation without changing behavior; tests must still pass
7. **Edge cases** — add tests for error paths, boundary values, and failure modes; repeat RED → GREEN for each
8. **Coverage gate** — confirm coverage of the new module hits 80%+

## Quick Start
```
/tdd-enforcer implement the UserSession service with login, logout, and token refresh
```

## Cycle Output
```
TDD Session: UserSession Service
=================================

PHASE 1 — RED
Writing tests to src/services/__tests__/user-session.test.ts

  ✗ login() returns session token for valid credentials        [NOT IMPLEMENTED]
  ✗ login() throws AuthError for wrong password               [NOT IMPLEMENTED]
  ✗ login() throws AccountLockedError after 5 failures        [NOT IMPLEMENTED]
  ✗ logout() invalidates the session token                    [NOT IMPLEMENTED]
  ✗ refreshToken() returns new token before expiry            [NOT IMPLEMENTED]
  ✗ refreshToken() throws for expired token                   [NOT IMPLEMENTED]

All 6 tests fail. RED confirmed.

PHASE 2 — GREEN
Implementing src/services/user-session.ts...

  ✓ login() returns session token for valid credentials
  ✓ login() throws AuthError for wrong password
  ✓ login() throws AccountLockedError after 5 failures
  ✓ logout() invalidates the session token
  ✓ refreshToken() returns new token before expiry
  ✓ refreshToken() throws for expired token

All 6 tests pass. GREEN confirmed.

PHASE 3 — REFACTOR
Extracted token generation to tokenUtils.ts
Tests still green.

Coverage: UserSession service — 94%
```

## Rules Enforced
- Test file is created before implementation file
- Implementation is not written until RED is confirmed (tests fail)
- No test is modified to make it pass (implementation must change, not tests)
- Each edge case gets its own test — no combining conditions in one `it()`
- No `it.skip()` or `test.todo()` left in place as "done"

## Related Skills
- `coverage-gap-analyzer` — find gaps after the fact if TDD was skipped
- `flaky-test-hunter` — if tests pass unreliably after implementation
