---
name: feature-flag-auditor
description: Audits feature flags for stale flags, missing environment configs, and flags ready to be cleaned up
tags: [architecture, feature-flags, cleanup, launchdarkly, technical-debt]
tools: Read, Grep, Glob, Bash
---

# Feature Flag Auditor

## When to Use
- Quarterly feature flag cleanup sprint
- When a feature has been fully rolled out and the flag is no longer needed
- Before a major release — confirm all flags are configured correctly in production
- When code is getting hard to read because of nested flag checks
- When a new engineer asks "what does this flag do?"

## How It Works

1. **Discover all flags** — grep for flag check patterns (`isEnabled`, `getFlag`, `variation`, `ld.variation`)
2. **Map flag usage** — which files, functions, and code paths check each flag?
3. **Classify flag age** — when was the flag check added? (git blame)
4. **Identify cleanup candidates** — flags that: (a) have been 100% on for 30+ days, (b) have been 0% on and abandoned, (c) exist in code but not in the flag management tool
5. **Identify missing configs** — flags referenced in code that aren't configured in all environments
6. **Generate cleanup plan** — ordered removal steps for each stale flag

## Quick Start
```
/feature-flag-auditor
```

## Output Format
```
Feature Flag Audit
==================
Flags found in code: 23
Environments checked: development, staging, production

CLEANUP CANDIDATES

[READY TO REMOVE] CHECKOUT_V2_ENABLED
  Status: 100% on in all environments for 47 days
  Usage: 8 locations in src/checkout/
  Action: Remove flag checks, delete the old code path, clean up from LaunchDarkly
  Effort: 2 hours
  Code to remove:
    src/checkout/processor.ts:34 — if (ld.variation('CHECKOUT_V2_ENABLED')) else block
    src/checkout/ui.tsx:67 — conditional render of old CartSummary component

[ABANDONED] DARK_MODE_BETA
  Status: 0% on, no changes in 6 months
  Last modified: 2023-11-14 (git blame)
  Usage: 3 locations
  Action: Remove flag and code — appears to have been abandoned
  Risk: LOW (never exposed to users)

MISSING ENVIRONMENT CONFIG

[WARNING] AI_RECOMMENDATIONS_ENABLED
  Present in: code, development, staging
  Missing from: production
  Effect: Flag will resolve to default (false) in production
  Code location: src/recommendations/engine.ts:12
  Action: Add to production config or confirm intentional

HEALTHY FLAGS
  15 flags are actively toggled and properly configured across environments

CLEANUP SUMMARY
  Flags to remove now: 2 (saves ~45 lines of code)
  Flags to configure: 1
  Flags to monitor: 3 (newly added, under active rollout)
```

## Related Skills
- `tech-debt-scorer` — stale flags contribute to architecture debt score
- `dependency-audit` — LaunchDarkly SDK updates sometimes needed when cleaning flags
