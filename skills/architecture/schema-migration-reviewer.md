---
name: schema-migration-reviewer
description: Reviews database migration files for safety, reversibility, lock risk, and production impact before apply
tags: [architecture, database, migration, postgres, safety]
tools: Read, Grep, Glob, Bash
---

# Schema Migration Reviewer

## When to Use
- Before running `prisma migrate deploy` or `alembic upgrade head` in production
- When reviewing a PR that includes migration files
- When a migration has been sitting in staging and is about to go to production
- Before any migration on a table with more than 1 million rows

## How It Works

1. **Parse migration files** — find all pending migration SQL or ORM migration files
2. **Classify each operation** — SAFE (no lock risk), CAREFUL (brief lock), DANGEROUS (full table lock / data loss risk)
3. **Check for lock-heavy operations** — `ADD COLUMN NOT NULL without DEFAULT`, `ALTER COLUMN TYPE`, full table rewrites
4. **Check for data loss** — DROP TABLE, DROP COLUMN, DELETE without WHERE, TRUNCATE
5. **Check for missing guards** — `IF NOT EXISTS`, `IF EXISTS`, idempotency
6. **Check reversibility** — does a down migration exist? Is it correct?
7. **Estimate impact** — table size × operation type → lock duration estimate
8. **Output** — per-operation verdict with alternatives

## Quick Start
```
/schema-migration-reviewer
```
Review a specific migration:
```
/schema-migration-reviewer migrations/20240615_add_tier_to_users.sql
```

## Output Format
```
Schema Migration Review
=======================
Migration: 20240615_add_tier_to_users.sql
Table: users (estimated rows: 2.4M)

OPERATION 1 — ALTER TABLE users ADD COLUMN tier VARCHAR(50)
  Risk: LOW
  Lock: Brief AccessExclusiveLock during catalog update only (milliseconds on Postgres 11+)
  Verdict: SAFE to run in production
  Note: Adding nullable column with no default is safe on Postgres 11+

OPERATION 2 — UPDATE users SET tier = 'free' WHERE tier IS NULL  
  Risk: MEDIUM
  Lock: Row-level locks during update — no table lock, but 2.4M rows = ~40 seconds
  Verdict: CAUTION — run in batches to avoid long transaction
  Alternative:
    DO $$
    DECLARE batch_size INT := 10000; offset_val INT := 0;
    BEGIN
      LOOP
        UPDATE users SET tier = 'free' WHERE tier IS NULL LIMIT batch_size;
        EXIT WHEN NOT FOUND;
        PERFORM pg_sleep(0.1);
      END LOOP;
    END $$;

OPERATION 3 — ALTER TABLE users ALTER COLUMN tier SET NOT NULL
  Risk: HIGH
  Lock: Full table scan to verify constraint — AccessExclusiveLock for ~30s on 2.4M rows
  Verdict: DANGEROUS for zero-downtime deploy
  Alternative: Use a CHECK constraint with NOT VALID, then validate separately:
    ALTER TABLE users ADD CONSTRAINT users_tier_not_null CHECK (tier IS NOT NULL) NOT VALID;
    -- Deploy and verify all rows have tier set, then:
    ALTER TABLE users VALIDATE CONSTRAINT users_tier_not_null;

DOWN MIGRATION CHECK
  Down migration: DROP COLUMN tier
  Verdict: CORRECT and safe

SUMMARY
  Safe to apply as-is: NO
  Recommended: Apply operations 1 and 2 in one deploy, operation 3 in a separate deploy after backfill stabilizes
```

## Lock Risk Reference
| Operation | Lock Type | Risk |
|-----------|-----------|------|
| ADD COLUMN (nullable, no default) | Brief catalog lock | Safe |
| ADD COLUMN NOT NULL without DEFAULT | Full rewrite | Dangerous |
| DROP COLUMN | Brief catalog lock | Safe (data loss) |
| ALTER COLUMN TYPE | Full table rewrite | Dangerous |
| CREATE INDEX | Table scan | Use CONCURRENTLY |
| ADD CONSTRAINT NOT VALID | No lock | Safe |
| VALIDATE CONSTRAINT | ShareLock | Careful |

## Related Skills
- `db-query-reviewer` — query-level review (not migration files)
- `migration-planner` — multi-phase strategy when the migration is complex
- `deployment-readiness-checker` — run before deploying the migration
