---
name: api-design-reviewer
description: Audits REST/GraphQL API design for consistency, security, and developer experience before merge
tags: [code-review, api, rest, graphql, dx]
tools: Read, Grep, Glob, Bash
---

# API Design Reviewer

## When to Use
- A PR adds or modifies endpoints, resolvers, or route handlers
- You're designing a new API surface before implementation
- An existing API has grown inconsistently and needs an audit
- Before writing SDK or client code against a new API

## How It Works

1. **Discover the API surface** — find all route definitions, controllers, resolvers, and schema files
2. **Consistency check** — naming conventions (casing, plural/singular), versioning strategy, error envelope format
3. **Security check** — auth/authz on every mutating endpoint, rate limiting, input validation, sensitive data in URLs
4. **DX check** — pagination on list endpoints, filtering/sorting params, response shape predictability, HTTP status codes
5. **Breaking change check** — compare against previous version if git history is available
6. **Output findings** — grouped by severity with line references and suggested fixes

## Quick Start
```
/api-design-reviewer
```
Or target a specific file:
```
/api-design-reviewer src/routes/users.ts
```

## Output Format
```
API Design Review
=================
Surface: 12 endpoints across 4 route files

CRITICAL (must fix before merge)
  [C1] POST /users/resetPassword — sensitive op in GET-style URL, should be POST /users/password-reset
  [C2] GET /admin/users — no auth middleware applied (routes/admin.ts:47)

HIGH (should fix)
  [H1] List endpoints missing pagination: GET /orders, GET /products, GET /comments
  [H2] Inconsistent error format: 6 endpoints return {error: string}, 3 return {message: string}

MEDIUM (consider fixing)
  [M1] Mixed casing: /userProfile vs /user-profile vs /users/{id}/profile
  [M2] 201 vs 200 on creates inconsistent across controllers

LOW (optional)
  [L1] No rate limiting on public search endpoints
```

## Example

Given a route file:
```typescript
router.get('/userProfile/:id', getProfile)     // wrong casing
router.get('/admin/users', listAdminUsers)      // missing auth
router.post('/resetpassword', resetPassword)    // wrong HTTP method pattern
router.get('/orders', listOrders)              // no pagination
```

Review flags: casing inconsistency, missing auth, method mismatch, unbounded list — all before the code ships.

## Related Skills
- `security-vuln-auditor` — deeper auth/authz analysis
- `db-query-reviewer` — the data layer backing these endpoints
- `schema-migration-reviewer` — if the API change drives a schema change
