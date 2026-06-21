---
name: tech-debt-scorer
description: Scores a codebase's technical debt across 6 dimensions and generates a prioritized remediation backlog
tags: [architecture, tech-debt, quality, refactoring, planning]
tools: Read, Grep, Glob, Bash
---

# Tech Debt Scorer

## When to Use
- Quarterly engineering health review
- Before planning a major feature that touches legacy code
- When a new engineer needs to understand the state of the codebase
- To make the case to stakeholders for refactoring investment
- Before an acquisition technical due diligence

## How It Works

1. **Code age** — find files not touched in 12+ months that still have active test coverage (i.e., code that's maintained but stagnant)
2. **Complexity score** — identify functions with cyclomatic complexity > 10 (too many branches), files > 800 lines
3. **Test debt** — coverage below 80%, large untested files in core paths, no E2E tests
4. **Dependency debt** — outdated major versions, known CVEs, deprecated packages
5. **Architecture debt** — circular imports, missing abstraction layers, God objects (single files that import 20+ modules)
6. **Documentation debt** — exported functions/classes with no docstring, outdated README, missing ADRs
7. **Score each dimension** — 1-10 (10 = no debt, 1 = critical debt)
8. **Generate prioritized backlog** — highest-impact items first, with effort estimate

## Quick Start
```
/tech-debt-scorer
```
Focus on a subsystem:
```
/tech-debt-scorer src/services/
```

## Output Format
```
Tech Debt Score
===============
Codebase: MyApp API
Scanned: 87 files, 23,400 LOC

DIMENSION SCORES
  Code Complexity:    4/10  — 12 functions with cyclomatic complexity >15
  Test Coverage:      5/10  — 61% overall; payments module at 34%
  Dependency Health:  6/10  — 2 CVEs, 8 packages at major version behind
  Architecture:       3/10  — 3 circular deps, AuthService imports 31 modules
  Documentation:      5/10  — 67% of exported functions lack docstrings
  Code Age:           7/10  — majority of code touched in last 6 months

OVERALL SCORE: 5.0/10 — Moderate debt, targeted remediation recommended

PRIORITY BACKLOG

P1 — High Impact, Low-Medium Effort
  [ ] Break circular dependencies: auth ↔ user ↔ session (est. 2 days)
      Files: src/auth/index.ts ↔ src/users/service.ts ↔ src/sessions/manager.ts
  [ ] Add tests to payments module: 34% → 80% (est. 3 days)
      5 core functions have zero test coverage

P2 — High Impact, High Effort  
  [ ] Split AuthService (31 imports, 890 lines) into 3 focused services (est. 5 days)
      AuthService, TokenService, PermissionsService

P3 — Medium Impact, Low Effort
  [ ] Patch 2 CVEs: npm install lodash@4.17.21 xmldom@0.8.8 (est. 30 min)
  [ ] Add docstrings to 14 exported functions in src/api/ (est. 2 hours)

P4 — Low Impact
  [ ] Reduce complexity in OrderProcessor.process() — complexity 22 (refactor to state machine)
  [ ] Update 8 packages to current major version (breaking changes — needs test run)
```

## Related Skills
- `dependency-audit` — full dependency health details
- `coverage-gap-analyzer` — find the specific test gaps in low-coverage modules
- `migration-planner` — plan the architectural changes flagged in P1/P2
