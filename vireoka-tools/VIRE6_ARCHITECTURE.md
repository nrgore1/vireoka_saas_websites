# Vire 6 — Architecture (Executive + Technical)

## Pipeline
Sense → Think → Simulate → Act (guarded) → Report

### Sense (existing V5)
- rsync diffing
- conflict detection
- dashboard

### Think (V6)
- risk scoring (category + heuristics)
- policy evaluation (`vire_policy.yaml`)
- deterministic resolution plan

### Simulate (V6)
- dry-run rsync to show blast radius before writes

### Act (V6 guarded)
- apply-safe only logs and then runs normal sync, relying on active-only filtering + rsync changed-only behavior

### Report (V6)
- plain-English explanation (LLM optional)
- audit log

## Safety properties
- No silent high-risk overwrites
- Always generates an explanation + plan
- Policy is explicit, versioned, reviewable
