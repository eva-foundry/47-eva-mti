# STATUS — EVA Machine Trust Index (47-eva-mti)

**Last Updated:** 2026-02-23 17:30 ET  
**Phase:** Design complete -- ADO artifacts ready -- implementation Sprint-1 not yet started  
**Maturity:** poc

---

## Summary

This project was created on Feb 23, 2026 by separating the MTI and Trust Service specifications out of `19-ai-gov`. The architectural decision: trust computation (subscores, formulas, Trust Service API, `actor_trust_scores` Cosmos container) is a distinct microservice concern from governance policy design.

All specification content is complete and inherited. No implementation exists yet. The source specs remain in `19-ai-gov` as reference copies -- this project holds the authoritative PLAN, STATUS, ACCEPTANCE, and copilot-instructions for anyone implementing the Trust Service.

---

## Session Log

### 2026-02-23 17:30 ET -- Architecture Brief, WBS, and ADO Artifacts Created

**Action:** Full platform context learning + production-ready ADO artifact set.

**Platform context learned (parallel reads):**
- EVA-JP-v1.2 rebuild scope (React 19 / Fluent UI v9 / GC Design System / APIM / FastAPI)
- 31-eva-faces (admin + chat + portal, 212 tests, prod readiness 38/100)
- 33-eva-brain-v2 (FastAPI, 60 endpoints, 577 tests, Sprint 6 deploying Container Apps)
- 29-foundry (MAF agents, MCP servers, 6 Copilot skills -- candidate host for Trust Service)
- 19-ai-gov (9-step Decision Engine, Trust Service called at step 5)
- 38-ado-poc (artifact schema confirmed: epic + features + user_stories)
- 40-eva-control-plane (evidence spine, evidence_id: GH{run}-PR{pr}-{sha})

**Created:**
- `docs/20260223-architecture-brief.md` -- 7-layer platform architecture diagram, dependency chain, comparison table, 10 design principles
- `docs/20260223-mti-wbs.md` -- complete WBS (9 sections), 9 Epics (E1-E9), 25 Features, 69 User Stories (MTI-1 to MTI-69), 6-sprint plan
- `ado-artifacts.json` -- ADO-importable: 1 Epic + 9 Features + 69 PBIs fully specified (titles, AC, tags, sprint iteration_path, parent mappings)
- `ado-import.ps1` -- delegates to `38-ado-poc/scripts/ado-import-project.ps1` with -DryRun support

**Sprint mapping (in ado-artifacts.json):**

| Sprint | Epic | Stories | Focus |
|---|---|---|---|
| Sprint-1 | E1 | MTI-1 to MTI-8 | YAML remediation, scaffold, auth, Cosmos, data model |
| Sprint-2 | E2 + E3 | MTI-9 to MTI-24 | 6 subscores, composition, all query endpoints |
| Sprint-3 | E4 + E5 | MTI-25 to MTI-36 | Signal pipeline, Decision Engine integration |
| Sprint-4 | E6 | MTI-37 to MTI-44 | Signal emitter wiring (brain-v2, APIM, control-plane, rbac, red-teaming) |
| Sprint-5 | E7 + E8 | MTI-45 to MTI-59 | Admin screens (5), TrustBandIndicator, chat-face, portal-face |
| Sprint-6 | E9 | MTI-60 to MTI-69 | OTel, KQL Workbook, CI/CD, FinOps, alerts, SLA verification |

**Blockers unresolved:**
- 37-data-model: `GET /model/projects/47-eva-mti` still returns 404 -- MTI-6/7/8 not yet done
- ARI signal schema not yet agreed with 36-red-teaming (MTI-43 blocker)
- Trust Service runtime host not yet decided (candidate: 29-foundry Container App)

**To run ADO import (after PAT is set):**
```powershell
cd C:\AICOE\eva-foundation\47-eva-mti
.\ado-import.ps1 -DryRun   # validates schema
.\ado-import.ps1            # live import into eva-poc project
```

---

### 2026-02-23 16:33 ET -- Project Created

**Action:** AI Agent Expert assessment of 19-ai-gov resulted in MTI separation decision.

**Separation rationale:**
- MTI is a computational service (subscores, formulas, signal ingestion, async recompute) -- distinct from governance policy design
- Trust Service has its own OpenAPI surface, its own Cosmos container (`actor_trust_scores`), and its own async signal pipeline
- Multiple EVA projects (33-eva-brain-v2, 29-foundry, 17-apim, 40-eva-control-plane) call or feed the Trust Service directly
- A single owning project for the Trust Service contract prevents spec fragmentation

**Created:**
- `README.md` -- project identity, MTI overview, Trust Service API summary, relationship diagram
- `PLAN.md` -- design phases (inherited from 19-ai-gov) + open implementation phases
- `STATUS.md` -- this file
- `ACCEPTANCE.md` -- acceptance criteria for Trust Service implementation

**Not created yet:**
- `.github/copilot-instructions.md` -- to be created when implementation begins
- Implementation specs in this folder (spec copies remain in 19-ai-gov)
- Clean YAML (HTML entity remediation pending)

---

## Design Artifacts (Reference Copies in 19-ai-gov)

| File (in 19-ai-gov) | What it defines | State |
|---|---|---|
| `EVA-Machine-trust-Index.md` | MTI concept, 6 subscores, trust bands, graduated autonomy | [DONE] |
| `eva-mti-scope.md` | ITI/BTI/CTI/ETI/STI/ARI definitions, data sources, formulas | [DONE] |
| `eva-mti-actions-matrix.md` | Trust band to allowed-action mapping (9 categories) | [DONE] |
| `eva-mti-compute-specs.md` | Computation YAML spec (HTML entity issue -- reference only) | [DONE] |
| `eva-mti-trust-service-api.md` | OpenAPI 3.0 Trust Service contract (HTML entity issue -- reference only) | [DONE] |
| `eva-api-n-cosmos-container.md` | actor_trust_scores container schema (within full container doc) | [DONE] |

---

## Known Issues

| Issue | Impact | Resolution |
|---|---|---|
| `eva-mti-compute-specs.md`: YAML uses `&nbsp;` HTML entities | Not parse-ready -- reference only | Strip entities when starting implementation (M-09) |
| `eva-mti-trust-service-api.md`: same HTML entity issue | Not parse-ready -- reference only | Same as above |
| ARI signal pipeline requires 36-red-teaming integration | Unknown data format for red team evaluation results | Resolve during M-08 |
| BTI decay model `half_life_days` is configurable -- no default set for production | Unknown operational default | Decide during Trust Service implementation |

---

## What Is Not Here

The following are not yet resolved:

- Where the Trust Service API runs (host, port, container image) -- candidate is 29-foundry Container App, port 8030
- ARI signal schema agreed with 36-red-teaming (MTI-43 blocker)
- 47-eva-mti project record in 37-data-model (MTI-6, MTI-7, MTI-8 in Sprint-1)
- Integration test harness (planned Sprint-2 onwards)
- Working CI/CD pipeline (planned MTI-65 Sprint-6)
