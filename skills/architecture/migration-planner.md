---
name: migration-planner
description: Creates a phased, zero-downtime migration plan for database schema changes, API versions, or service splits
tags: [architecture, migration, database, zero-downtime, planning]
tools: Read, Grep, Glob, Bash
---

# Migration Planner

## When to Use
- Renaming or removing a database column/table
- Splitting a monolith service into two separate services
- Deprecating a v1 API while launching v2
- Moving from one data store to another (e.g., Postgres → DynamoDB for a hot path)
- Any change that requires coordinating code and data state across multiple deploys

## How It Works

1. **Understand current state** — map the existing schema, API contracts, or service boundaries
2. **Define target state** — what does the system look like after migration?
3. **Identify coupling points** — what reads/writes the thing being migrated? Cross-service dependencies?
4. **Design the phases** — break into stages where each stage is independently deployable and the system is functional between stages
5. **Write phase-by-phase plan** — each phase: what changes, what's deployed, how to verify, how to roll back
6. **Flag irreversible steps** — steps where data can be lost or can't be easily undone
7. **Generate dual-write or shadow mode strategies** where needed

## Quick Start
```
/migration-planner rename users.username to users.handle
```
```
/migration-planner deprecate POST /api/v1/orders in favor of /api/v2/orders
```

## Output Format
```
Migration Plan: Rename users.username → users.handle
=====================================================
Risk: MEDIUM | Estimated duration: 2-3 deploy cycles | Downtime required: NONE

Current state:
  Table: users
  Column: username (VARCHAR 255, NOT NULL, UNIQUE)
  Used by: 14 query locations across 6 files

PHASE 1 — Expand (Deploy 1)
  Goal: Both column names exist; old column is still source of truth
  Changes:
    - Migration: ALTER TABLE users ADD COLUMN handle VARCHAR(255)
    - Backfill: UPDATE users SET handle = username WHERE handle IS NULL
    - Add UNIQUE constraint to handle
    - Code: all WRITES go to both username and handle (dual-write)
    - Code: all READS still use username
  Verify: SELECT COUNT(*) FROM users WHERE handle IS NULL → should be 0
  Rollback: DROP COLUMN handle (safe, new column only)

PHASE 2 — Migrate Reads (Deploy 2)
  Goal: Reads switch to handle; writes still go to both
  Changes:
    - Code: all READS switch to handle
    - Code: writes still dual-write to both columns
  Verify: grep -r "\.username" src/ → only dual-write locations remain
  Rollback: revert code (handle column still exists, no data loss)

PHASE 3 — Contract (Deploy 3)
  Goal: Remove old column; writes go to handle only
  Changes:
    - Code: remove dual-write; write only to handle
    - Migration: ALTER TABLE users DROP COLUMN username
  Verify: SELECT column_name FROM information_schema.columns WHERE table_name='users'
  ⚠ IRREVERSIBLE: username column data is gone. Confirm Phase 2 has been stable for 1+ week.
  Rollback: not possible without data restore — ensure backup taken before this deploy

API Version Example
-------------------
Phase 1: Add v2 endpoint, v1 still active, both return same shape
Phase 2: Update all internal clients to v2, deprecation header on v1
Phase 3: Remove v1 after monitoring shows 0 traffic for 2 weeks
```

## Related Skills
- `schema-migration-reviewer` — safety review of the migration SQL itself
- `dependency-audit` — if migration involves removing a dependency
- `rollback-planner` — detailed rollback steps per phase
