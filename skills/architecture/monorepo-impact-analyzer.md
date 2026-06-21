---
name: monorepo-impact-analyzer
description: Analyzes a change in a monorepo to determine which packages, services, and pipelines are affected
tags: [architecture, monorepo, ci, impact-analysis, dependencies]
tools: Read, Grep, Glob, Bash
---

# Monorepo Impact Analyzer

## When to Use
- Before merging a PR in a monorepo — understand blast radius
- When a shared utility or package is changed and you need to know who consumes it
- When CI is slow and you want to understand which test suites actually need to run
- When planning a breaking change in a shared library
- When a bug in a shared package causes mysterious failures in unrelated services

## How It Works

1. **Detect monorepo structure** — find workspace configs (pnpm-workspace.yaml, nx.json, turbo.json, Cargo.toml workspaces, go.work)
2. **Map package dependency graph** — which packages import which other packages
3. **Identify changed packages** — `git diff --name-only HEAD~1` → map files to packages
4. **Trace impact** — for each changed package, traverse the dependency graph to find all consumers (direct and transitive)
5. **Map to CI pipelines** — which services/apps are affected → which test suites must run
6. **Identify breaking change risk** — if a public API/type changed, flag all consumers that may need updates
7. **Output** — affected package list, required test suites, and any consumers needing manual review

## Quick Start
```
/monorepo-impact-analyzer
```
Analyze a specific package change:
```
/monorepo-impact-analyzer packages/ui-components
```

## Output Format
```
Monorepo Impact Analysis
========================
Changed files: 12 (in packages/auth-client)
Monorepo tool: Turborepo

CHANGED PACKAGE
  @myapp/auth-client (packages/auth-client)
  Changed: AuthClient.refreshToken() signature — added optional `force` parameter
  Breaking change risk: LOW (additive parameter with default value)

DIRECT CONSUMERS (import @myapp/auth-client)
  apps/web-app          — uses AuthClient in 6 files
  apps/mobile-app       — uses AuthClient in 4 files
  packages/api-client   — re-exports AuthClient methods

TRANSITIVE CONSUMERS (import a consumer of auth-client)
  apps/admin-panel      — via @myapp/api-client

REQUIRED TEST SUITES
  ✓ packages/auth-client (unit tests)
  ✓ apps/web-app (unit + E2E — touches auth flow)
  ✓ apps/mobile-app (unit tests)
  ✓ packages/api-client (unit tests)
  ⚠ apps/admin-panel (run if api-client tests fail)

SKIP SAFELY
  packages/design-system — no auth dependency
  apps/marketing-site    — no auth dependency
  packages/analytics     — no auth dependency

CI OPTIMIZATION
  Full CI: 28 minutes across all packages
  Targeted CI: 14 minutes (only affected packages)
  Save: 50% CI time by scoping to affected packages

MANUAL REVIEW NEEDED
  None — no breaking changes detected
  If signature had been breaking: apps/web-app:src/hooks/useAuth.ts, apps/mobile-app:src/auth/session.ts
```

## Related Skills
- `tech-debt-scorer` — tight coupling in the dependency graph is an architecture debt signal
- `dependency-audit` — audit external dependencies in the affected packages
- `ci-failure-diagnosis` — if the targeted CI run fails unexpectedly
