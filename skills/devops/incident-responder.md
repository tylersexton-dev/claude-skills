---
name: incident-responder
description: Guides structured incident response — triage, diagnosis, mitigation, communication, and postmortem
tags: [devops, incident, on-call, production, postmortem]
tools: Read, Grep, Glob, Bash
---

# Incident Responder

## When to Use
- Production is down or degraded
- Error rate or latency has spiked beyond threshold
- A customer has reported a critical bug in production
- You're on-call and just got paged
- After an incident — to write the postmortem

## How It Works

1. **Triage** — establish severity: P0 (all users affected), P1 (subset of users), P2 (degraded experience), P3 (cosmetic/minor)
2. **Timebox investigation** — set a 10-minute investigation window before escalating or mitigating
3. **Identify scope** — which services, endpoints, or user segments are affected?
4. **Recent changes** — what deployed in the last 24 hours? Any config or infra changes?
5. **Mitigation options** — generate ranked options: rollback, feature flag off, scale up, kill switch, cache bypass
6. **Communication** — draft status page update and internal Slack message
7. **Postmortem template** — after resolution, generate a structured 5-why analysis

## Quick Start (active incident)
```
/incident-responder p1 checkout endpoint returning 500s since 14:32 UTC
```

## Postmortem mode
```
/incident-responder postmortem
```

## Incident Output Format
```
INCIDENT RESPONSE — P1
=======================
Declared: 14:45 UTC | Incident Commander: [you]
Symptom: checkout endpoint returning 500s

TRIAGE
  Severity: P1 — subset of users blocked from completing purchase
  User impact: ~340 checkout attempts failed in last 15 min
  Revenue impact: estimated $4,200 blocked

RECENT CHANGES (last 24h)
  14:12 UTC — deploy release/2024-06-15 (includes payment processor update)
  13:50 UTC — Stripe API key rotated by ops team
  09:30 UTC — routine migration: add users.tier column

LIKELY CAUSE
  Stripe API key rotation at 13:50 correlates with failure onset at 14:32
  (20-min cache TTL on key = delayed failure onset)
  
MITIGATION OPTIONS (ranked)
  1. [FASTEST] Revert Stripe key to previous value — 2 min, no deploy needed
  2. Update STRIPE_SECRET_KEY env var to new rotated key — 3 min + deploy
  3. Roll back release/2024-06-15 — 6-8 min, eliminates payment processor change

RECOMMENDED ACTION
  Try option 1 first: check Stripe dashboard for old key, restore in secrets manager
  If not available, proceed to option 2

STATUS PAGE DRAFT
  "We are investigating elevated error rates on checkout. Our team has identified the
  cause and is actively working on a fix. We will update in 15 minutes."

COMMS — #incidents
  "P1 incident declared 14:45 UTC. Checkout 500s since ~14:32. Likely cause: Stripe
  key rotation. IC: @you. Investigating now, mitigation underway."
```

## Postmortem Template
```
## Incident Postmortem — [Title]

**Date:** | **Duration:** | **Severity:**

### Timeline
- HH:MM — [event]

### Root Cause
[5-why analysis]

### Impact
- Users affected:
- Duration:
- Revenue impact:

### What Went Well

### What Went Wrong

### Action Items
| Item | Owner | Due |
|------|-------|-----|
```

## Related Skills
- `rollback-planner` — generate rollback steps during mitigation
- `deployment-readiness-checker` — prevent incidents proactively
