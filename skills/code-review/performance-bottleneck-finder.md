---
name: performance-bottleneck-finder
description: Identifies N+1 queries, missing indexes, unbounded loops, and memory leaks in changed code
tags: [code-review, performance, database, memory, optimization]
tools: Read, Grep, Glob, Bash
---

# Performance Bottleneck Finder

## When to Use
- A PR touches data fetching, loops over collections, or adds new query patterns
- Users report slowness in a specific feature after a deploy
- Before a load test or traffic spike
- When a query starts appearing in slow query logs

## How It Works

1. **Scan for N+1 patterns** — find `.find()`, `.get()`, or query calls inside loops or `.map()` / `.forEach()`
2. **Scan for unbounded queries** — SELECT without LIMIT on endpoints that could return large datasets
3. **Scan for missing index candidates** — WHERE clauses on columns that are likely unindexed based on schema
4. **Scan for memory patterns** — large array accumulation, missing stream usage for file/response processing, sync blocking in async contexts
5. **Scan for render/recompute waste** — in frontend code, expensive computations not memoized, unnecessary re-renders
6. **Estimate impact** — flag HIGH if pattern scales with user count or data size; MEDIUM if bounded; LOW if isolated

## Quick Start
```
/performance-bottleneck-finder
```
Target a specific area:
```
/performance-bottleneck-finder src/services/orders.ts
```

## Output Format
```
Performance Review
==================
Files scanned: 11

HIGH IMPACT
  [H1] N+1 query — src/services/orders.ts:67
       for (const order of orders) {
         const items = await db.orderItems.findMany({ where: { orderId: order.id } })
       }
       Impact: 1 query per order → 100 orders = 101 queries
       Fix: use include: { orderItems: true } in the parent query, or batch with IN clause

  [H2] Unbounded list query — src/api/products.ts:23
       Product.findAll()  // no limit, no pagination
       Impact: returns all rows as dataset grows
       Fix: add { limit: 50, offset: page * 50 }

MEDIUM IMPACT
  [M1] Sync file read in request handler — src/routes/reports.ts:44
       fs.readFileSync(path)
       Fix: use fs.promises.readFile() or stream for large files

LOW IMPACT
  [L1] Array built with repeated push in loop — src/utils/transform.ts:12
       Could pre-allocate or use .map() for clarity
```

## Patterns Checked
- N+1: query calls inside `for`, `.map()`, `.forEach()`, `.filter()` chains
- Unbounded: `findAll()`, `SELECT *` without `LIMIT`, `.all()` without pagination
- Sync I/O in async context: `readFileSync`, `writeFileSync`, `execSync`
- Missing memoization: expensive functions called in React render without `useMemo`
- Accumulator anti-patterns: `result = [...result, item]` in a loop (O(n²))

## Related Skills
- `db-query-reviewer` — deeper analysis of raw SQL and ORM query patterns
- `coverage-gap-analyzer` — ensure perf-critical paths have tests before optimizing
