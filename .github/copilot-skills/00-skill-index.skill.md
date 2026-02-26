---
skill: 00-skill-index
version: 1.0.0
project: 47-eva-mti
last_updated: 2026-02-23
---

# Skill Index -- EVA Machine Trust Index

> This is the skills menu for 47-eva-mti.
> Read this file first when the user asks: "what skills are available", "what can you do", or "list skills".
> Then read the matched skill file in full before starting any work.

## Project Context

**Goal**: Trust computation engine for EVA AI.Gov -- 6-subscore Machine Trust Index, Trust Service API, async signal pipeline
**37-data-model record**: `GET /model/projects/47-eva-mti`
**Governance specs (source)**: `C:\AICOE\eva-foundation\19-ai-gov\eva-mti-*.md`
**Phase**: Design complete (inherited). Implementation not started.

---

## Available Skills

| # | File | Trigger phrases | Purpose |
|---|------|-----------------|---------|
| 0 | 00-skill-index.skill.md | list skills, what can you do, skill menu | This index |

---

## Planned Skills (add when implementation begins)

| Planned skill | Trigger phrases | Purpose |
|---|---|---|
| `01-subscore-compute.skill.md` | implement subscore, add iti, add bti, compute trust | Step-by-step guide for implementing a single subscore with correct formula, decay, and penalty |
| `02-trust-service-endpoint.skill.md` | add endpoint, implement evaluateTrust, implement signal | Guide for adding a new Trust Service API endpoint with auth, schema validation, Cosmos write |
| `03-signal-pipeline.skill.md` | signal pipeline, wire signal source, connect red team | Guide for wiring a new signal source (BTI/ARI/ETI/STI) to the `/signal` endpoint |
| `04-yaml-remediation.skill.md` | fix yaml, strip entities, remediate spec | Guide for stripping `&nbsp;` HTML entities from spec files and producing clean YAML |
| `05-mti-spec-review.skill.md` | review spec, check formula, verify weights | Guide for cross-checking an implementation against the inherited MTI computation spec |

---

## Skill Creation Guide

Each skill file follows this structure:

```yaml
---
skill: [skill-name]
version: 1.0.0
triggers:
  - "[trigger phrase 1]"
  - "[trigger phrase 2]"
---

# Skill: [Name]
## Context
## Steps
## Validation
## Anti-patterns
```

Files live in: `.github/copilot-skills/`

---

## Key Reference Files (in 19-ai-gov -- read before implementing)

| File | What to read it for |
|---|---|
| `eva-mti-scope.md` | Exact definitions and data sources for each of the 6 subscores |
| `eva-mti-compute-specs.md` | Formulas, weights per actor type, decay model, missing signal penalty (YAML -- strip &nbsp; first) |
| `eva-mti-actions-matrix.md` | Trust band to allowed-action mapping -- use for AC test assertions |
| `eva-mti-trust-service-api.md` | OpenAPI 3.0 contract -- request/response schemas, error codes, security (YAML -- strip &nbsp; first) |
| `eva-api-n-cosmos-container.md` | `actor_trust_scores` container schema -- fields, partition key, TTL |

---

*Template source*: `C:\AICOE\eva-foundation\07-foundation-layer`
*Skill framework*: `C:\AICOE\eva-foundation\02-poc-agent-skills`
*Governance boundary*: Decision Engine calling this Trust Service is in `19-ai-gov\eva-decision-engine-spec.md` step 5
