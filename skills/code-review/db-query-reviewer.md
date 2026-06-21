---
name: db-query-reviewer
description: Reviews database queries for correctness, safety, index usage, and transaction integrity
tags: [code-review, database, sql, orm, postgres, migrations]
tools: Read, Grep, Glob, Bash
---

# DB Query Reviewer

## When to Use
- A PR adds, modifies, or removes SQL queries or ORM calls
- A migration file is added
- Query performance is degrading in production
- Before adding a new reporting or analytics query
- When a new engineer writes their first data layer code

## How It Works

1. **Find all queries** — locate raw SQL strings, ORM method chains, migration files
2. **Safety check** — parameterization (no string interpolation in queries), DELETE without WHERE, UPDATE without WHERE
3. **Index check** — WHERE clauses on columns likely to lack indexes; ORDER BY on non-indexed columns with large tables
4. **Transaction check** — multi-step writes (insert + update + delete) not wrapped in a transaction; missing rollback handling
5. **Migration check** — destructive operations without backup strategy, missing `IF EXISTS` guards, lock-heavy operations on large tables
6. **ORM misuse** — lazy loading traps, `.count()` on large tables, missing `.select()` causing SELECT *

## Quick Start
```
/db-query-reviewer
```
Target migrations specifically:
```
/db-query-reviewer migrations/
```

## Output Format
```
DB Query Review
===============
Queries found: 18 across 6 files | Migrations: 2

CRITICAL
  [C1] Unparameterized query — src/db/search.ts:31
       db.query(`SELECT * FROM users WHERE email = '${email}'`)
       Fix: db.query('SELECT * FROM users WHERE email = $1', [email])

  [C2] DELETE without WHERE — migrations/20240615_cleanup.sql:8
       DELETE FROM sessions;  -- deletes ALL sessions
       Fix: add WHERE clause or confirm this is intentional with a comment

HIGH
  [H1] Missing transaction — src/services/checkout.ts:44-67
       order insert + inventory decrement + payment record are 3 separate awaits
       Fix: wrap in db.transaction(async (trx) => { ... })

  [H2] Full table scan on large table — src/reports/analytics.ts:12
       SELECT * FROM events WHERE created_at > '2024-01-01'
       events table: no index on created_at
       Fix: CREATE INDEX idx_events_created_at ON events(created_at)

MEDIUM
  [M1] SELECT * in production query — src/api/users.ts:88
       Returns password_hash and internal fields to caller
       Fix: explicitly select needed columns

  [M2] Migration adds NOT NULL column without default — migrations/20240618_add_tier.sql
       ALTER TABLE users ADD COLUMN tier VARCHAR NOT NULL;
       Fix: add DEFAULT 'free' or migrate existing rows first
```

## Migration Safety Checklist
- [ ] Adds index CONCURRENTLY (not blocking) for large tables
- [ ] DROP TABLE / DROP COLUMN has a data backup or is on empty table
- [ ] NOT NULL columns have a DEFAULT or a prior backfill migration
- [ ] RENAME operations are two-phase (add new, dual-write, drop old)
- [ ] Migration is idempotent (IF NOT EXISTS, IF EXISTS guards)

## Related Skills
- `schema-migration-reviewer` — dedicated migration safety review
- `performance-bottleneck-finder` — broader performance patterns beyond queries
- `security-vuln-auditor` — catches injection vulnerabilities at the code level
