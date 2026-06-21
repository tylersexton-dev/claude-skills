---
name: ci-failure-diagnosis
description: Diagnoses CI pipeline failures by reading logs, identifying root causes, and generating a fix plan
tags: [devops, ci, debugging, github-actions, pipeline]
tools: Read, Grep, Glob, Bash
---

# CI Failure Diagnosis

## When to Use
- A CI pipeline fails and the error isn't immediately obvious
- Tests pass locally but fail in CI
- Build succeeds locally but fails in the pipeline
- A pipeline that was passing starts failing after a dependency update
- You need to hand off a CI failure investigation to someone without context

## How It Works

1. **Locate logs** — find CI output in `.github/workflows/`, `Jenkinsfile`, or `circle.yml`; or accept pasted log as input
2. **Identify failure type** — classify: build failure, test failure, lint/type error, flaky test, environment issue, dependency resolution error, timeout
3. **Extract the signal** — find the first failing line (not just the last error summary, which is often misleading)
4. **Diff against local** — compare CI environment assumptions (Node version, OS, env vars) against local setup
5. **Identify the fix** — environment mismatch, missing secret, version pin needed, test isolation issue, or actual regression
6. **Output a fix plan** — specific commands to reproduce locally and the exact change needed to fix CI

## Quick Start
```
/ci-failure-diagnosis
```
Paste CI log output directly after the command, or point to a log file:
```
/ci-failure-diagnosis .github/logs/run-4892.txt
```

## Output Format
```
CI Failure Diagnosis
====================
Pipeline: GitHub Actions — test.yml
Failure type: TEST FAILURE (not a build or environment issue)

Root Cause
  Test: "auth middleware rejects expired tokens"
  File: src/middleware/__tests__/auth.test.ts:67
  First failing line: expect(received).toBe(401) — received 200

  Why it passes locally:
    Local: Node 20.x, jest 29.7
    CI: Node 18.x, jest 29.5 — timers mock API differs between versions

Reproduction
  nvm use 18 && npm ci && npx jest src/middleware/__tests__/auth.test.ts

Fix Plan
  Option A (recommended): Pin CI to Node 20 in .github/workflows/test.yml
    - node-version: '18'
    + node-version: '20'

  Option B: Fix test to be timer-version agnostic
    Replace jest.runAllTimers() with jest.runAllTimersAsync() (compatible 18+)

Secondary finding
  3 other tests have similar timer patterns — may fail in other environments
  Run: grep -r "runAllTimers" src/
```

## Failure Type Playbooks

**Build failure** — check: tsconfig errors, missing type exports, version mismatch in compilers  
**Test failure in CI only** — check: Node version, timezone (CI often UTC), env vars missing, filesystem case sensitivity (Linux vs macOS)  
**Dependency resolution error** — check: lockfile not committed, registry auth, private package access  
**Timeout** — check: test hitting real network, infinite loop in setup, missing `done()` callback  
**Lint/type error** — check: stricter tsconfig in CI (`--noEmit --strict`), different ESLint rule set  

## Related Skills
- `deployment-readiness-checker` — run before pushing to prevent CI failures
- `flaky-test-hunter` — if CI failure is intermittent
