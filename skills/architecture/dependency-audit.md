---
name: dependency-audit
description: Audits project dependencies for security vulnerabilities, outdated versions, unused packages, and license issues
tags: [architecture, dependencies, security, supply-chain, npm, pip]
tools: Read, Grep, Glob, Bash
---

# Dependency Audit

## When to Use
- Quarterly dependency health check
- Before a major version upgrade
- After a security disclosure mentioning a library you use
- Before open-sourcing a project (license audit)
- When bundle size has grown unexpectedly
- When onboarding to a codebase and assessing technical debt

## How It Works

1. **Detect package manager** — find package.json, requirements.txt, go.mod, Cargo.toml, pyproject.toml
2. **Run security scan** — `npm audit`, `pip-audit`, `cargo audit`, `go list -m -json all | nancy`
3. **Find outdated packages** — `npm outdated`, `pip list --outdated`
4. **Find unused packages** — depcheck (npm), `pip-autoremove --leaves`, or grep for imports vs installed packages
5. **License audit** — flag GPL, AGPL, LGPL dependencies in commercial projects
6. **Bundle impact** — for frontend projects, identify largest dependencies and check if they have lighter alternatives
7. **Output** — actionable report with severity, upgrade commands, and alternatives where applicable

## Quick Start
```
/dependency-audit
```
License-only mode:
```
/dependency-audit --licenses
```

## Output Format
```
Dependency Audit
================
Package manager: npm
Total dependencies: 127 (94 prod, 33 dev)
Last audit: never

CRITICAL (CVE, patch available)
  lodash@4.17.20 — CVE-2021-23337 (Command Injection via template)
    Severity: HIGH | CVSS: 7.2
    Fix: npm install lodash@4.17.21
    
  xmldom@0.1.27 — CVE-2021-32796 (ReDoS)
    Severity: HIGH
    Fix: npm install xmldom@0.8.8
    Transitive via: xml2js → xmldom (you don't install directly)
    Fix path: npm install xml2js@0.6.0 (includes patched xmldom)

OUTDATED (major version behind)
  react@17.0.2 → 18.3.0 (major)
    Breaking changes: check migration guide before upgrading
  typescript@4.9.5 → 5.5.2 (major)
    Non-trivial upgrade — may surface type errors

UNUSED PACKAGES (not imported anywhere)
  colors@1.4.0 — not found in any import
  moment@2.29.4 — only src/legacy/date.ts imports this (1 file); replace with date-fns

LICENSE ISSUES
  gpl-3.0-licensed-lib@2.1.0 — GPL-3.0 is copyleft
    Risk: distributing a commercial product with GPL code may require open-sourcing your code
    Fix: find MIT-licensed alternative or consult legal

BUNDLE SIZE WINNERS (replace to reduce bundle)
  moment@2.29.4 — 67kb gzipped → date-fns equivalent: 4kb (tree-shakeable)
  lodash@4.17.21 — 24kb → use native JS methods or lodash-es with tree-shaking

HEALTHY
  ✓ 119 packages have no known CVEs
  ✓ No packages 3+ major versions behind
```

## Related Skills
- `security-vuln-auditor` — vulnerabilities in your own code, not dependencies
- `tech-debt-scorer` — dependency age is one component of tech debt score
