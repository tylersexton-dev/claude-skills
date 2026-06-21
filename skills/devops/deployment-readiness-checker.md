---
name: deployment-readiness-checker
description: Runs a pre-deployment checklist covering tests, migrations, feature flags, secrets, and rollback plan
tags: [devops, deployment, checklist, production, release]
tools: Read, Grep, Glob, Bash
---

# Deployment Readiness Checker

## When to Use
- Before merging a release branch or deploying to production
- When a deployment has been risky or caused incidents before
- When handing off a deployment to another engineer
- For any change that involves schema migrations, config changes, or new external dependencies

## How It Works

1. **Test gate** — confirm test suite passes and coverage hasn't dropped
2. **Migration check** — detect pending migrations; verify they're backwards-compatible with the current code version
3. **Feature flag check** — identify new features guarded by flags; confirm flags are configured in the target environment
4. **Secret/env check** — compare `.env.example` against production environment; flag missing vars
5. **Dependency check** — flag any newly added dependencies not yet audited; check for known CVEs if `npm audit` / `pip-audit` available
6. **Rollback plan** — generate step-by-step rollback instructions based on what changed
7. **Traffic impact estimate** — identify endpoints that changed and estimate user impact scope
8. **Output** — READY TO DEPLOY or BLOCKED with specific items to resolve

## Quick Start
```
/deployment-readiness-checker
```
Target environment:
```
/deployment-readiness-checker production
```

## Output Format
```
Deployment Readiness Check
==========================
Target: production
Branch: release/2024-06-15

STATUS: BLOCKED — 2 items require resolution

BLOCKING
  [B1] Pending migration not backwards-compatible
       migrations/20240615_drop_legacy_user_column.sql
       Column users.legacy_id is dropped — current production code (v2.3.1) still reads this column
       Fix: deploy code change FIRST, verify old column is unused, THEN run migration

  [B2] Missing production secret
       STRIPE_WEBHOOK_SECRET not set in production environment
       Required by: src/api/webhooks/stripe.ts:12
       Fix: add to production secrets manager before deploying

WARNINGS (can deploy, but note these)
  [W1] New dependency added: sharp@0.33.3 (native binary)
       Requires native build on production OS — verify Lambda/container has build tools
  
  [W2] Feature flag CHECKOUT_V2 not found in production LaunchDarkly
       3 new endpoints gated behind this flag won't be accessible until flag is created

PASSED CHECKS
  ✓ All tests pass (847 passing, 0 failing)
  ✓ Coverage: 83% (above 80% threshold)
  ✓ No known CVEs in new dependencies
  ✓ .env.example in sync with production (except flagged item above)

Rollback Plan (if needed)
  1. Revert deploy: git revert HEAD && push to trigger redeploy
  2. Database: migration 20240615 has a down() function — run: npx migrate down 1
  3. Estimated rollback time: ~4 minutes
  4. No data loss risk (additive migration only)
```

## Related Skills
- `rollback-planner` — dedicated rollback strategy generation
- `schema-migration-reviewer` — deeper migration safety analysis
- `ci-failure-diagnosis` — if CI blocks the deployment
