---
name: rollback-planner
description: Generates a step-by-step rollback plan for a deployment, including database, cache, and feature flag reversion
tags: [devops, rollback, incident, production, recovery]
tools: Read, Grep, Glob, Bash
---

# Rollback Planner

## When to Use
- Before any production deployment (generate rollback plan in advance)
- During an incident when a recent deployment needs to be reverted
- When planning a risky migration or infrastructure change
- When writing a deployment runbook

## How It Works

1. **Understand what changed** — analyze `git diff main...HEAD` for code changes, migrations, config, dependencies
2. **Categorize risk per change type** — code (low risk to roll back), migration (medium to high), data writes (potentially irreversible), external service changes (dependency on third party)
3. **Build ordered rollback steps** — reversion must be in reverse order of deployment (undo last thing first)
4. **Flag irreversible operations** — data deletions, email sends, payment captures can't be undone; note mitigations
5. **Estimate time and impact** — how long will rollback take? What user-facing impact during rollback?
6. **Generate the runbook** — literal commands, not prose

## Quick Start
```
/rollback-planner
```
For a specific deployment:
```
/rollback-planner release/2024-06-15
```

## Output Format
```
Rollback Plan — release/2024-06-15
====================================
Generated: 2024-06-15 14:32 UTC
Estimated rollback time: 6-8 minutes
Data loss risk: LOW (no destructive operations)

ROLLBACK SEQUENCE

Step 1 — Revert application code (2 min)
  git revert --no-commit HEAD
  git commit -m "revert: rollback release/2024-06-15"
  git push origin main
  # Triggers auto-deploy — watch for deployment completion in Render/Railway/ECS

Step 2 — Revert database migration (3 min)
  Migration: 20240615_add_user_tier.sql
  Down migration available: YES
  Command: npx prisma migrate resolve --rolled-back 20240615_add_user_tier
  # Or if using raw SQL:
  # psql $DATABASE_URL -c "ALTER TABLE users DROP COLUMN IF EXISTS tier"
  
  WARNING: If any users have been assigned a tier since deployment,
  that data will be lost. Check: SELECT COUNT(*) FROM users WHERE tier IS NOT NULL;

Step 3 — Clear cache (1 min)
  Redis keys prefixed with "user:tier:" will have stale data
  Command: redis-cli --scan --pattern "user:tier:*" | xargs redis-cli del

Step 4 — Revert feature flags (30 sec)
  LaunchDarkly flag TIER_PRICING: set to OFF
  Command: ld-api feature-flags update TIER_PRICING --enabled false

Step 5 — Verify
  curl -s https://api.example.com/health | jq '.version'
  # Should return previous version number
  Run smoke tests: npm run test:smoke -- --env=production

IRREVERSIBLE OPERATIONS IN THIS DEPLOY
  - Tier welcome emails sent to 0 users at deploy time (emails cannot be unsent)
  - No payments processed under new pricing (safe)

NOTIFY
  - Post in #incidents: "Rolling back release/2024-06-15 — ETA complete: XX:XX"
  - Update status page if user-facing impact
```

## Related Skills
- `deployment-readiness-checker` — generate rollback plan BEFORE deploying
- `incident-responder` — if rollback is happening during an active incident
