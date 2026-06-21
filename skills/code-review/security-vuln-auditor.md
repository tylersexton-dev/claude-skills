---
name: security-vuln-auditor
description: Scans changed code for OWASP Top 10 vulnerabilities, secret leaks, and injection vectors
tags: [code-review, security, owasp, secrets, injection]
tools: Read, Grep, Glob, Bash
---

# Security Vulnerability Auditor

## When to Use
- Any PR that touches auth, payments, user input handling, or file I/O
- Before deploying new user-facing features
- After adding a new dependency
- When onboarding a new engineer's first few PRs
- Periodic security sweep of a codebase you inherited

## How It Works

1. **Diff scope** — identify changed files via `git diff --name-only HEAD~1` or target a directory
2. **Secret scan** — grep for patterns matching API keys, tokens, passwords, connection strings in code and config
3. **Injection scan** — find string concatenation in SQL, shell commands, HTML templates, eval calls
4. **Auth scan** — locate route handlers and middleware; verify every mutating op has auth/authz applied
5. **Input validation scan** — check all external entry points (form fields, URL params, headers, file uploads) for validation before use
6. **Dependency scan** — flag known vulnerable packages if package.json / requirements.txt / go.mod changed
7. **Output** — severity-ranked findings with file:line references and remediation snippets

## Quick Start
```
/security-vuln-auditor
```
Target a directory:
```
/security-vuln-auditor src/api/
```

## Output Format
```
Security Audit
==============
Files scanned: 23 | Changed in diff: 8

CRITICAL
  [C1] Hardcoded API key — src/integrations/stripe.ts:14
       const key = "sk_live_4xT9..."
       Fix: move to process.env.STRIPE_SECRET_KEY

  [C2] SQL injection — src/db/users.ts:88
       `SELECT * FROM users WHERE email = '${email}'`
       Fix: use parameterized query: db.query('...WHERE email = $1', [email])

HIGH
  [H1] Missing auth on DELETE /api/posts/:id — src/routes/posts.ts:34
       Fix: add requireAuth middleware before handler

  [H2] Unvalidated file upload extension — src/uploads/handler.ts:19
       Fix: whitelist allowed MIME types before writing to disk

MEDIUM
  [M1] Error message exposes stack trace to client — src/middleware/error.ts:8
       Fix: return generic message in production, log full trace server-side
```

## Key Patterns Checked
- Hardcoded secrets: `sk_`, `pk_`, `Bearer `, `password =`, `token =`, `-----BEGIN`
- SQL injection: string template literals in query calls, `.raw(`, `.query(\``
- XSS: `innerHTML =`, `dangerouslySetInnerHTML`, unescaped template variables
- Command injection: `exec(`, `spawn(`, `system(` with dynamic input
- Path traversal: `fs.readFile(req.params`, `path.join(userInput`
- CSRF: state-changing POST/PUT/DELETE without CSRF token check

## Related Skills
- `api-design-reviewer` — catches auth gaps at the route design level
- `dependency-audit` — deeper dependency vulnerability analysis
