# claude-skills

A library of production-ready skills for [Claude Code](https://claude.ai/code). Drop any skill into `~/.claude/skills/` and invoke it by name from any project.

Each skill is a battle-tested workflow — not documentation. It gives Claude enough context to execute a real task end-to-end without further prompting.

---

## Quick Install

**Install everything:**
```bash
curl -fsSL https://raw.githubusercontent.com/tylersexton-dev/claude-skills/main/install.sh | bash
```

**Install manually:**
```bash
git clone https://github.com/tylersexton-dev/claude-skills.git
cd claude-skills
./install.sh
```

**Install a single category:**
```bash
./install.sh --category testing
```

---

## Skill Catalog

### Code Review

| Skill | What It Does |
|-------|-------------|
| `api-design-reviewer` | Audits REST/GraphQL APIs for consistency, auth gaps, and DX issues |
| `security-vuln-auditor` | Scans for OWASP Top 10 vulnerabilities, secret leaks, and injection vectors |
| `performance-bottleneck-finder` | Finds N+1 queries, unbounded loops, missing indexes, and memory issues |
| `db-query-reviewer` | Reviews SQL/ORM queries for safety, index usage, and transaction integrity |

### Testing

| Skill | What It Does |
|-------|-------------|
| `coverage-gap-analyzer` | Identifies untested paths and generates failing test stubs for the gaps |
| `tdd-enforcer` | Enforces red-green-refactor — writes tests first, drives implementation to pass |
| `flaky-test-hunter` | Diagnoses tests that pass unreliably due to timing, shared state, or external deps |
| `test-data-factory` | Generates realistic factories, fixtures, and seed data from your data models |

### DevOps

| Skill | What It Does |
|-------|-------------|
| `ci-failure-diagnosis` | Diagnoses CI pipeline failures and generates a fix plan |
| `deployment-readiness-checker` | Pre-deployment checklist: tests, migrations, secrets, rollback plan |
| `rollback-planner` | Generates step-by-step rollback runbook for any deployment |
| `incident-responder` | Guides structured incident response and postmortem generation |

### Architecture

| Skill | What It Does |
|-------|-------------|
| `migration-planner` | Creates phased, zero-downtime migration plans for schema or API changes |
| `dependency-audit` | Audits dependencies for CVEs, outdated versions, unused packages, license issues |
| `tech-debt-scorer` | Scores technical debt across 6 dimensions and generates a prioritized backlog |
| `schema-migration-reviewer` | Reviews migration SQL for lock risk, data loss, and reversibility |
| `feature-flag-auditor` | Finds stale flags, missing configs, and flags ready for cleanup |
| `monorepo-impact-analyzer` | Maps which packages and pipelines are affected by a change |

---

## Usage

Once installed, invoke any skill from Claude Code with a slash command:

```
/api-design-reviewer
```

```
/security-vuln-auditor src/api/
```

```
/tdd-enforcer implement UserSession service with login, logout, token refresh
```

```
/incident-responder p1 checkout returning 500s since 14:32 UTC
```

Each skill accepts optional arguments to scope its analysis. When invoked without arguments, it analyzes the current project.

---

## How Skills Work

Skills are Markdown files with YAML frontmatter. Claude Code reads them from `~/.claude/skills/` and treats them as executable instructions — not just documentation.

When you invoke `/skill-name`, Claude loads the skill file and follows its step-by-step workflow, using only the tools declared in the frontmatter.

---

## Contributing

Skills must meet the quality bar:

- **Concrete trigger conditions** — not "use whenever." When specifically?
- **Numbered steps** — Claude follows them in order
- **Realistic examples** — actual code snippets, not toy examples
- **Output format** — users know what to expect before they run it
- **Cross-references** — link to related skills where the workflow chains

File format:
```markdown
---
name: skill-name
description: One precise sentence
tags: [category, keyword]
tools: Read, Grep, Glob, Bash
---

# Skill Title

## When to Use
## How It Works
## Quick Start
## Output Format
## Example
## Related Skills
```

Submit a PR. Skills that are vague, generic, or produce placeholder output will be rejected.

---

## License

MIT
