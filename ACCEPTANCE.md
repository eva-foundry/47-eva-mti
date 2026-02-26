# ACCEPTANCE — EVA Machine Trust Index (47-eva-mti)

**Date:** 2026-02-23 16:33 ET  
**Owner:** AICOE

> These are the system-level acceptance criteria for the EVA Trust Service implementation.  
> They describe what a correct implementation of this design must satisfy — not how to build it.  
> Source specs: `eva-mti-compute-specs.md`, `eva-mti-scope.md`, `eva-mti-actions-matrix.md`, `eva-mti-trust-service-api.md` (all in 19-ai-gov as reference copies).
>
> AC-02 in `19-ai-gov/ACCEPTANCE.md` cross-references these criteria. If a criterion appears in both, this file is authoritative for the Trust Service implementation.

---

## AC-T01 · Subscore Computation

| ID | Criterion | Verification |
|---|---|---|
| AC-T01-1 | `POST /trust/evaluateTrust` returns all 6 subscores (iti, bti, cti, eti, sti, ari) and compositeMti in every response | Response schema validation |
| AC-T01-2 | Each subscore is clamped to [0, 100] | Unit test: inject extreme inputs, assert clamp |
| AC-T01-3 | Composite MTI is computed as weighted sum of 6 subscores with actor-type-specific weights, not a simple average | Unit test: HUMAN vs AGENT weights differ for same signals |
| AC-T01-4 | Composite MTI maps to the correct trust band at all 5 band boundaries (0-29, 30-49, 50-69, 70-84, 85-100) | Unit test: boundary values 0, 29, 30, 49, 50, 69, 70, 84, 85, 100 |
| AC-T01-5 | A BTI violation 28 days old has 1/4 the weight of the same violation today (exponential decay, half_life=14 days) | Unit test: violation dated today vs 28 days ago |
| AC-T01-6 | Missing required signal applies the configured `unknown_signal_penalty` -- does not silently default to 0 | Unit test: remove ITI signal source, verify penalty applied |
| AC-T01-7 | `providedTrust` in request body is accepted when `recomputeTrustAlways=false` -- Trust Service skips recompute | Integration test: pre-supply MTI, verify no compute calls |

---

## AC-T02 · Trust Service API

| ID | Criterion | Verification |
|---|---|---|
| AC-T02-1 | `POST /trust/evaluateTrust` accepts the full TrustEvaluateRequest schema and returns TrustEvaluateResponse | Schema-based integration test |
| AC-T02-2 | `GET /trust/getActorTrust/{actorId}` returns current and historical scores; `?history=true` includes time series | API test with known actor |
| AC-T02-3 | `POST /trust/signal` returns 202 Accepted and triggers async MTI recompute within 60 seconds | Signal → poll getActorTrust test |
| AC-T02-4 | All endpoints require Entra ID bearer token; requests without auth receive HTTP 401 | Negative test: no token |
| AC-T02-5 | Callers without TRUST_READER role receive HTTP 403 on `/getActorTrust` | RBAC negative test |
| AC-T02-6 | Invalid request body returns HTTP 400 with field-level error details | Negative test: missing actorId |
| AC-T02-7 | `POST /trust/evaluateTrust` p95 latency is <= 150 ms under load (catalog cached) | Load test: 100 concurrent requests |

---

## AC-T03 · Actor Trust Store (`actor_trust_scores`)

| ID | Criterion | Verification |
|---|---|---|
| AC-T03-1 | Every successful `/evaluateTrust` call writes a record to `actor_trust_scores` with all 6 subscores, composite, timestamp, and context snapshot | Cosmos query after test call |
| AC-T03-2 | Trust scores for an actor are retrievable 30 days after evaluation | Query with 30-day-old timestamp |
| AC-T03-3 | `actor_trust_scores` records are append-only -- no UPDATE or DELETE operations | Attempt PATCH/DELETE on container, expect error |
| AC-T03-4 | MTI snapshot stored in `governance_evaluations` (19-ai-gov) matches the score returned by `/evaluateTrust` for the same correlationId | Cross-container join test |

---

## AC-T04 · Signal Processing

| ID | Criterion | Verification |
|---|---|---|
| AC-T04-1 | A BTI signal (policy violation) received via `/signal` reduces the actor's BTI in the next evaluation | Signal → re-evaluate → compare scores |
| AC-T04-2 | An ARI signal (hallucination detected) received via `/signal` reduces the actor's ARI in the next evaluation | Signal → re-evaluate → compare scores |
| AC-T04-3 | An ETI signal (evidence pack validated) received via `/signal` increases the actor's ETI in the next evaluation | Signal → re-evaluate → compare scores |
| AC-T04-4 | Duplicate signals within a configurable deduplication window (default 5 min) are idempotent -- score does not compound | Send same signal 3x, verify single effect |
| AC-T04-5 | Signal processing failure does not crash the Trust Service -- bad signals are DLQ'd and logged | Send malformed signal, verify service health |

---

## AC-T05 · Actor Type Coverage

| ID | Criterion | Verification |
|---|---|---|
| AC-T05-1 | HUMAN actor MTI computed correctly using HUMAN weight table | Integration test with actorType=HUMAN |
| AC-T05-2 | AGENT actor MTI computed correctly using AGENT weight table; ARI is non-zero | Integration test with actorType=AGENT |
| AC-T05-3 | SERVICE actor MTI computed correctly; ARI defaults to 100 (services have no hallucination risk) | Integration test with actorType=SERVICE |
| AC-T05-4 | SYSTEM actor MTI computed correctly; BTI defaults to 100 (systems have no behavioural autonomy) | Integration test with actorType=SYSTEM |
| AC-T05-5 | An AGENT without `ari` signal data receives the `missing_signal_penalty` on ARI | Test: AGENT with no red team results |

---

## AC-T06 · Decision Engine Integration (Caller Contract)

> These criteria verify that the Trust Service correctly satisfies the caller contract expected by the 19-ai-gov Decision Engine at step 5.

| ID | Criterion | Verification |
|---|---|---|
| AC-T06-1 | `TrustEvaluateResponse` includes `compositeMti`, all 6 subscores, `trustBand`, and `computationVersion` | Response schema check in Decision Engine integration test |
| AC-T06-2 | Trust Service returns HTTP 200 for any valid context envelope -- never 404 for unknown actorId (score is computed with defaults) | Test with actor not in trust store |
| AC-T06-3 | Trust Service response includes the same `correlationId` as the request | Trace validation |
| AC-T06-4 | When Trust Service is unavailable, calling system (Decision Engine) applies DENY-safe behavior -- Trust Service does not cause silent ALLOW | Kill Trust Service → Decision Engine test |
| AC-T06-5 | Trust Service version is included in the response (`computationVersion`) so audit records can trace back to formula version | Version field check in response |

---

## AC-T07 · Non-Functional

| ID | Criterion | Value |
|---|---|---|
| AC-T07-1 | `/evaluateTrust` p95 latency (catalog cached) | <= 150 ms |
| AC-T07-2 | `/getDecision` p95 latency (chained with Decision Engine) | <= 200 ms |
| AC-T07-3 | `/signal` write acknowledgment (202) | <= 30 ms |
| AC-T07-4 | Signal-to-score-update propagation | <= 60 s |
| AC-T07-5 | Trust Service availability over any 30-day window | >= 99.5% |
| AC-T07-6 | `actor_trust_scores` container supports 1M actor records with <= 10 ms Cosmos read | Cosmos performance test |
| AC-T07-7 | All Trust Service endpoints are protected by Entra ID bearer auth | Security scan pass |

---

## Specification References

| AC Group | Primary Spec | Location |
|---|---|---|
| AC-T01 Subscore Computation | `eva-mti-scope.md`, `eva-mti-compute-specs.md` | 19-ai-gov (reference copy) |
| AC-T02 Trust Service API | `eva-mti-trust-service-api.md` | 19-ai-gov (reference copy) |
| AC-T03 Actor Trust Store | `eva-api-n-cosmos-container.md` | 19-ai-gov (reference copy) |
| AC-T04 Signal Processing | `eva-mti-trust-service-api.md` /signal endpoint | 19-ai-gov (reference copy) |
| AC-T05 Actor Type Coverage | `eva-mti-compute-specs.md` weight tables | 19-ai-gov (reference copy) |
| AC-T06 Decision Engine Integration | `eva-decision-engine-spec.md` step 5 | 19-ai-gov |
| AC-T07 Non-Functional | `eva-mti-trust-service-api.md` performance section | 19-ai-gov (reference copy) |
