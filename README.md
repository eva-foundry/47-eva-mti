# 47-eva-mti — EVA Machine Trust Index

**Status:** Design complete — Trust Service specification ready for implementing teams  
**Owner:** AICOE  
**Created:** 2026-02-23 16:33 ET  
**Maturity:** poc

---

## What This Project Is

`47-eva-mti` is the **trust computation specification and design authority** for the EVA Machine Trust Index (MTI).

It does not ship running code. It ships the complete trust computation design: 6 subscore definitions, computation formulas and weights, trust band mapping, allowed-actions matrix, and the full OpenAPI 3.0 contract for the Trust Service API. Implementing teams consume these specs and build the Trust Service microservice.

**Origin:** MTI specs were developed as part of `19-ai-gov` (EVA AI Governance Plane) and separated into this project on Feb 23, 2026 because trust computation is architecturally distinct from governance policy design. The governance Decision Engine calls the Trust Service at step 5 (`resolve_or_compute_trust`) via `POST /trust/evaluateTrust`.

---

## Core Concept

> Trust is not binary. It is computed.  
> Six independent domain signals combine into a Composite MTI score (0-100).  
> The score maps to a Trust Band. The band determines what the actor is allowed to do.

This is **policy in motion**: instead of static role checks, every actor's autonomy level is continuously evaluated based on evidence from their identity posture, behaviour history, compliance record, evidence quality, security signals, and AI reliability.

---

## The 6 Subscores

| Subscore | Measures | Primary Signal Sources |
|---|---|---|
| **ITI** -- Identity Trust Index | Authentication strength, MFA, ToU, role maturity | Entra ID, RBAC, ToU logs |
| **BTI** -- Behaviour Trust Index | Policy violation history, anomalous patterns, denied actions | `audit_events`, telemetry (App Insights, APIM) |
| **CTI** -- Compliance Trust Index | % of applicable controls satisfied, % obligations fulfilled | `governance_evaluations`, `obligation_instances` |
| **ETI** -- Evidence Trust Index | Evidence pack completeness, schema compliance, hash validation | `evidence_artifacts` |
| **STI** -- Security Trust Index | Prompt injection signals, data exfiltration indicators, anomaly detection | APIM, App Insights, threat telemetry |
| **ARI** -- Agent Reliability Index | Hallucination rate, grounding quality, red team evaluation results | EVA Brain telemetry, `36-red-teaming` |

**Composite MTI** = weighted sum of 6 subscores, clamped to [0, 100].

---

## Trust Bands

| Band | Score Range | Autonomy Level |
|---|---|---|
| HIGH TRUST | 85-100 | Fully autonomous -- all action categories allowed |
| TRUSTED | 70-84 | Allowed with monitoring |
| GUARDED | 50-69 | Human approval required for sensitive actions |
| LOW TRUST | 30-49 | Heavily restricted -- read-only or informational only |
| UNTRUSTED | 0-29 | Blocked -- no execution allowed |

---

## Trust Service API (4 Endpoints)

| Endpoint | Purpose |
|---|---|
| `POST /trust/evaluateTrust` | Compute all 6 subscores + Composite MTI for a given context envelope |
| `GET /trust/getActorTrust/{actorId}` | Retrieve current and historical MTI scores for an actor |
| `POST /trust/getDecision` | Execute full 9-step governance Decision Engine (calls governance layer); returns decision + obligations |
| `POST /trust/signal` | Ingest a trust signal event (BTI delta, ARI update, ETI change) and trigger async MTI recompute |

> Note: `/getDecision` is a convenience endpoint that chains the Trust Service into the Decision Engine. The canonical Decision Engine spec is in `19-ai-gov`. The Trust Service is the compute layer; `19-ai-gov` is the policy layer.

Full OpenAPI 3.0 contract: `eva-mti-trust-service-api.md` (reference copy from 19-ai-gov).

---

## MTI Computation Model

### Formula

```
CompositeScore = clamp(
  w_iti * ITI + w_bti * BTI + w_cti * CTI +
  w_eti * ETI + w_sti * STI + w_ari * ARI
  - context_risk_adjustment
, 0, 100)
```

Where weights (`w_*`) are defined per actor type (HUMAN vs AGENT vs SERVICE vs SYSTEM) in `eva-mti-compute-specs.md`.

### Decay Model

Negative events (violations, anomalies) decay in severity over time:

```
weight(t_days) = exp(-ln(2) * t_days / half_life_days)
half_life = 14 days (configurable)
```

This means a violation 28 days ago has 1/4 the impact of the same violation today.

### Missing Signal Penalty

If a required signal is unavailable (data source offline, no telemetry), a configurable penalty is subtracted rather than silently defaulting to 0. This prevents trust inflation from data gaps.

---

## Source Material

These spec files originated in `19-ai-gov` and are the authoritative source for this project:

| File | What it defines |
|---|---|
| `eva-mti-scope.md` | ITI / BTI / CTI / ETI / STI / ARI -- definitions, data sources, formulas for each subscore |
| `eva-mti-compute-specs.md` | Computation spec (YAML) -- inputs, weights, decay, normalization; full actor-type weight tables |
| `eva-mti-actions-matrix.md` | Trust band to allowed-action mapping across 9 action categories |
| `EVA-Machine-trust-Index.md` | MTI concept, rationale, graduated autonomy model |
| `eva-mti-trust-service-api.md` | OpenAPI 3.0 contract for the Trust Service API |

> **Spec quality note:** The YAML blocks in `eva-mti-compute-specs.md` and `eva-mti-trust-service-api.md` contain `&nbsp;` HTML entities. They are reference documents -- not parse-ready YAML. Implementing teams must strip HTML entities before machine processing.

---

## Cosmos Container

| Container | Purpose | Owner |
|---|---|---|
| `actor_trust_scores` | MTI subscores + composite per actor, with full timestamp history | 47-eva-mti |

All other governance containers are owned by `19-ai-gov`.

---

## Relationship to 19-ai-gov

```
19-ai-gov (Governance Policy)           47-eva-mti (Trust Computation)
      |                                         |
      | Decision Engine                        | Trust Service
      | Steps 1-4: policy, hard-stops          | evaluateTrust: compute 6 subscores
      |                                         |
      | Step 5: POST /trust/evaluateTrust ----> |
      |         <---- TrustEvaluateResponse --- |
      |                                         |
      | Steps 6-11: controls, thresholds,      |
      |             aggregate, obligations,     |
      |             audit, respond              |
```

The interface is a single HTTP call with a well-defined request/response contract. Neither project has the other as a build dependency at design time.

---

## Related Projects

| Project | Relationship |
|---|---|
| [19-ai-gov](../19-ai-gov) | Governance policy layer; calls Trust Service at Decision Engine step 5 |
| [33-eva-brain-v2](../33-eva-brain-v2) | Emits BTI and ARI signals via `POST /trust/signal`; subject to MTI evaluation |
| [36-red-teaming](../36-red-teaming) | Produces ARI evaluation results consumed by the Trust Service |
| [29-foundry](../29-foundry) | Candidate runtime host for the Trust Service API |
| [17-apim](../17-apim) | Injects `STI` signals (prompt injection, anomaly) via trust signal endpoint |
| [40-eva-control-plane](../40-eva-control-plane) | Emits ETI signals when evidence packs are validated |
| [28-rbac](../28-rbac) | Source of role maturity signals for ITI computation |
