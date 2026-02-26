# EVA Platform -- Architecture Brief

**Date:** 2026-02-23  
**Author:** AI Agent Expert (GitHub Copilot)  
**Scope:** Full EVA Platform -- rebuild of EVA-JP-v1.2 from scratch  
**Status:** Reference document -- current state as of Feb 23, 2026

---

## Mission

Rebuild `EVA-JP-v1.2` (Microsoft PubSec Info Assistant fork) from scratch as a
production-grade, bilingual (EN/FR), WCAG 2.1 AA, AI-governed Canadian federal
government AI assistant. Clean React 19 / TypeScript / Fluent UI v9 frontend,
FastAPI backend, governed at runtime by the EVA AI Governance and Trust planes,
with full DevOps / FinOps / Observability.

---

## The 7 Layers

```
LAYER 0 -- Source of Truth Planes
  37-data-model  (port 8010)   ALL objects: screens, endpoints, containers,
                                agents, personas, literals, features
  38-ado-poc -> Azure DevOps   Epics / Features / PBIs / Sprints
                                dev.azure.com/marcopresta/eva-poc
  40-eva-control-plane (8020)  Runtime evidence: runs, step_runs, artifacts
                                evidence_id: GH{run}-PR{pr}-{sha}
                                propagated: PR check / Azure tag / ADO artifact / Cosmos
  GitHub eva-foundry org       30 private repos, GitHub Copilot in DPDCA loop

LAYER 1 -- Intelligence & Governance
  29-foundry    Agentic capabilities hub: MAF agents, MCP servers (AI Search,
                Cosmos, Blob), RAG pipeline, evaluation, OTel observability,
                6 Copilot skills (multi-agent, RAG, search, prompts, eval, trace)
  19-ai-gov     Governance policy layer: 12 domains, unified actor model
                (HUMAN/AGENT/SERVICE/SYSTEM), 9-step Decision Engine,
                11 Cosmos containers
  47-eva-mti    Trust computation layer: 6 subscores (ITI/BTI/CTI/ETI/STI/ARI)
                Composite MTI (0-100) -> Trust Band -> Allowed Actions
                Trust Service API: /evaluateTrust /getActorTrust /signal /getDecision

LAYER 2 -- Backend Services
  33-eva-brain-v2
    eva-brain-api  (port 8001)  60 endpoints, RAG, sessions, ingestion, personas
                                 (legal-researcher / legal-clerk / admin)
    eva-roles-api  (port 8002)  RBAC, persona switching, cost tag evaluation
  Stack: FastAPI / Azure OpenAI / Azure AI Search / Cosmos DB / Blob Storage
         Document Intelligence / Computer Vision / Translator / Storage Queues
  State: 577/577 tests passing -- Sprint 6 = deployment to Container Apps

LAYER 3 -- API Gateway
  17-apim -> marco-sandbox-apim
    4 product tiers -- JWT validation -- rate-limit-by-key
    ALL backend traffic routes through here
    Injects x-eva-* cost attribution headers on EVERY call:
      x-eva-user-id, x-eva-project-id, x-eva-business-unit,
      x-eva-client-id, x-eva-sprint, x-eva-wi-tag
    Headers feed FinOps (14-az-finops) and Observability (App Insights)

LAYER 4 -- Frontend
  31-eva-faces  (React 19 / Vite / Fluent UI v9 / GC Design System)
    admin-face/   10 screens built -- 188 tests -- VITE_MOCK_BACKEND=true
    chat-face/    ChatInterface built -- streaming/persona/RAG = Phase 3
    portal-face/  EVAHomePage + SprintBoard + AuthContext built
    shared/       @eva/gc-design-system -- @eva/ui (14 wrappers)
                  @eva/templates (AdminListPage, AuditLogPage, AdminEditPage)
  Constraints:
    WCAG 2.1 AA -- makeStyles/tokens only -- EN/FR i18n (react-i18next)
    Entra ID auth (dev-bypass today, tenant admin pending)
    No imports from @fluentui/react (v8) -- v9 only
  State: 212 tests -- prod readiness 38/100 -- target 80/100

LAYER 5 -- Observability / FinOps / DevOps
  App Insights    Wired in brain-v2 (OTel) and faces (AI SDK)
  Azure Monitor   Alerts, KQL Workbooks (Sprint 7 planned)
  FinOps          14-az-finops: Cost Mgmt export -> Power BI
                  Powered by x-eva-* APIM headers per call
  ADO             18 projects -- 18 Epics -- 55 PBIs
  CI/CD           GitHub Actions -> ACR -> Container Apps
                  evidence_id propagated across PR / Azure tag / ADO / Cosmos

LAYER 6 -- Azure Infrastructure
  marco-sandbox-openai        GPT-4o, gpt-4o-mini, text-embedding-ada-002
  marco-sandbox-foundry       Agent Framework model deployments
  marco-sandbox-search        Vector / keyword / hybrid AI Search
  marco-sandbox-cosmos        Sessions, jobs, audit, trust scores
  marcosandacr20260203 (ACR)  Container images
  marcosand20260203 (Blob)    Documents, evidence packs
  marco-sandbox-apim          Gateway (all traffic)
  marco-sandbox-appinsights   OTel telemetry
  Canada Central Container Apps  Runtime: brain-api + roles-api
```

---

## What EVA-JP-v1.2 Is Being Rebuilt As

| Original (EVA-JP-v1.2)       | Rebuilt As                                                          |
|------------------------------|---------------------------------------------------------------------|
| React + Fluent UI v8 mix     | React 19 + Fluent UI v9 only (31-eva-faces)                        |
| No a11y enforcement          | WCAG 2.1 AA -- jest-axe, forced-colors, ARIA, skip links           |
| English only                 | EN/FR bilingual via react-i18next                                   |
| Basic RAG chat               | RAG + grounded + ungrounded + web + Assistants modes               |
| No governance layer          | AI Governance Plane (19-ai-gov) -- 9-step Decision Engine, MTI     |
| Static RBAC (role checks)    | Dynamic trust-computed RBAC via MTI subscores (47-eva-mti)         |
| Direct API calls             | All traffic through APIM (17-apim) with cost attribution headers   |
| No cost visibility           | FinOps pipeline (14-az-finops) from APIM headers -> Power BI       |
| No evidence trail            | 40-eva-control-plane evidence_id spine across PR/deploy/Cosmos     |
| Manual development           | GitHub Copilot + Agent Fleet generating screens from Epic YAMLs    |
| No structured object catalog | 37-data-model: every screen, endpoint, container, literal, persona |
| No sprint integration        | 38-ado-poc dispatches DPDCA runners from ADO live backlog          |
| No trust computation         | 47-eva-mti: 6 subscores -> Composite MTI -> Trust Band -> Actions  |

---

## Platform Dependency Chain

```
31-eva-faces  (UI -- 3 faces)
    |
    | HTTPS (all routes)
    v
17-apim  (gateway -- all traffic -- x-eva-* headers injected)
    |
    +---> 33-eva-brain-v2 / eva-brain-api  (port 8001)
    |           |
    |           +---> Azure OpenAI (GPT-4o, embeddings)
    |           +---> Azure AI Search (hybrid RAG)
    |           +---> Azure Cosmos DB (sessions, jobs, audit)
    |           +---> Azure Blob + Queues (ingestion pipeline)
    |           +---> 33-eva-brain-v2 / eva-roles-api  (port 8002 -- RBAC)
    |           |
    |           +---> 19-ai-gov Decision Engine  (governance policy)
    |                       |
    |                       | Step 5: POST /trust/evaluateTrust
    |                       v
    |                 47-eva-mti Trust Service
    |                       |
    |                       +---> actor_trust_scores (Cosmos)
    |                       +---> Signal sources:
    |                             28-rbac (ITI)
    |                             33-eva-brain-v2 (BTI, ARI)
    |                             17-apim (STI)
    |                             40-eva-control-plane (ETI)
    |                             19-ai-gov runtime (CTI)
    |                             36-red-teaming (ARI)
    |
    +---> 40-eva-control-plane  (port 8020 -- evidence)
    +---> 37-data-model  (port 8010 -- catalog)
```

---

## Active Sprint Summary (Feb 23, 2026)

| Project           | Sprint | Next Action                                      | Blocker                                  |
|-------------------|--------|--------------------------------------------------|------------------------------------------|
| 33-eva-brain-v2   | 6      | Deploy to Container Apps                         | Dockerfile for roles-api; APIM policies  |
| 31-eva-faces      | Ph2    | WI-20: wire 29 admin APIs                        | brain-api Container App URL live         |
| 17-apim           | 7 plan | OpenAPI import, JWT, rate-limit, cost headers    | Depends on brain-api deployed            |
| 47-eva-mti        | --     | M-09 YAML remediation; begin Trust Service       | YAML HTML entities; no code yet          |
| 19-ai-gov         | --     | Design complete; awaits Trust Service build      | 47-eva-mti implementation                |
| 40-eva-control-plane | --  | RB-001 active                                    | None                                     |
| 37-data-model     | --     | Updated each session                             | 47-eva-mti project record not yet in API |
| 38-ado-poc        | --     | Dispatch runners; 18/18 projects in ADO          | 47-eva-mti epic not yet imported         |

---

## 47-eva-mti in Platform Context

`47-eva-mti` is the **trust computation microservice** called at step 5 of every
governance decision. It receives a context envelope from the 19-ai-gov Decision
Engine, computes 6 subscores plus Composite MTI, writes to `actor_trust_scores`
in Cosmos, and returns the trust band. That band determines what 33-eva-brain-v2
may do autonomously versus what requires human approval.
31-eva-faces reads the trust band for the Trust Indicator UI component visible
in the chat interface and admin dashboard.

The Trust Service is the enforcement point where governance becomes action.

---

## Key Design Principles

1. **Trust is computed, not assumed.** Every actor (HUMAN, AGENT, SERVICE, SYSTEM)
   gets a dynamic MTI score from 6 independent evidence dimensions.

2. **All traffic flows through APIM.** No frontend calls backend directly.
   Cost attribution headers are injected on every call.

3. **Evidence is first-class.** Every sprint produces an evidence_id that ties
   PR -> deployment -> telemetry -> ADO artifact in one traceable chain.

4. **Every object is in the data model.** 37-data-model is the single source of
   truth for all platform entities. Never grep source files when a model exists.

5. **Bilingual at every layer.** EN/FR i18n is not a wrapper; it is a first-class
   constraint enforced from UI strings (react-i18next) to backend literals
   (translations endpoints) to Cosmos (literal keys in model layer).

6. **A11y is not optional.** WCAG 2.1 AA is a gate, not a nice-to-have.
   jest-axe runs on every component. Forced-colors media queries are required.

7. **GitHub Copilot is the developer.** Every project has copilot-instructions
   that act as the operating manual. Skills in 29-foundry are the tools.
   38-ado-poc dispatches the DPDCA loop per active work item.

---

*Source projects: 31-eva-faces, 33-eva-brain-v2, 29-foundry, 19-ai-gov, 47-eva-mti,*
*37-data-model, 38-ado-poc, 40-eva-control-plane, 17-apim, 14-az-finops*  
*Generated: 2026-02-23 by AI Agent Expert session*
