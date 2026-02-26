# GitHub Copilot Instructions -- 47-eva-mti

**Template Version**: 3.2.0
**Last Updated**: February 25, 2026 10:14 ET
**Project**: 47-eva-mti -- {PROJECT_ONE_LINE_DESCRIPTION}
**Path**: `C:\AICOE\eva-foundry\47-eva-mti\`
**Stack**: {PROJECT_STACK}

> This file is the Copilot operating manual for this repository.
> PART 1 is universal -- identical across all EVA Foundation projects.
> PART 2 is project-specific -- customise the placeholders before use.

---

## PART 1 -- UNIVERSAL RULES
> Applies to every EVA Foundation project. Do not modify.

---

### 1. Session Bootstrap (run in this order, every session)

Before answering any question or writing any code:

1. **Establish $base** (ACA primary -- run the bootstrap block in Section 3.1 first):
   - ACA (24x7, Cosmos-backed, no auth): `https://marco-eva-data-model.livelyflower-7990bc7b.canadacentral.azurecontainerapps.io`
   - Local dev fallback only: `http://localhost:8010`
   - `$base` must be set before any model query in this session.

2. **Read this project's governance docs** (in order):
   - `README.md` -- identity, stack, quick start
   - `PLAN.md` -- phases, current phase, next tasks
   - `STATUS.md` -- last session snapshot, open blockers
   - `ACCEPTANCE.md` -- DoD checklist, quality gates (if exists)
   - Latest `docs/YYYYMMDD-plan.md` and `docs/YYYYMMDD-findings.md` (if exists)

3. **Read the skills index** (if `.github/copilot-skills/` exists):
   - List files: `Get-ChildItem .github/copilot-skills/ -Filter "*.skill.md" | Select-Object Name`
   - Read `00-skill-index.skill.md` or the first skill matching the current task's trigger phrase
   - Each skill has a `triggers:` YAML block -- match it to the user's intent

4. **Query the data model** for this project's record:
   ```powershell
   Invoke-RestMethod "$base/model/projects/{PROJECT_FOLDER}" | Select-Object id, maturity, notes
   ```

5. **Produce a Session Brief** -- one paragraph: active phase, last test count, next task, open blockers.
   Do not skip this. Do not start implementing before the brief is written.

---

### 2. DPDCA Execution Loop

Every session runs this cycle. Do not skip steps.

```
Discover  --> synthesise current sprint from plan + findings docs
Plan      --> pick next unchecked task from yyyymmdd-plan.md checklist
Do        --> implement -- make the change, do not just describe it
Check     --> run the project test command (see PART 2); must exit 0
Act       --> update STATUS.md, PLAN.md, yyyymmdd-plan.md, findings doc
Loop      --> return to Discover if tasks remain
```

**Execution Rule**: Make the change. Do not propose, narrate, or ask for permission on a step you can determine yourself. If uncertain about scope, ask one clarifying question then proceed.

---

### 3. EVA Data Model API -- Mandatory Protocol

> **GOLDEN RULE**: The `model/*.json` files are an internal implementation detail of the API server.
> Agents must never read, grep, parse, or reference them directly -- not even to "check" something.
> The HTTP API is the only interface. One HTTP call beats ten file reads.
> The API self-documents: `GET /model/agent-guide` returns the complete operating protocol.

> **Full reference**: `C:\AICOE\eva-foundry\37-data-model\USER-GUIDE.md` (v2.5)
> The model is the single source of truth. One HTTP call beats 10 file reads.
> Never grep source files for something the model already knows.

#### 3.1  Bootstrap

```powershell
# Primary -- ACA (24x7 Cosmos-backed, no auth required, always up)
$base = "https://marco-eva-data-model.livelyflower-7990bc7b.canadacentral.azurecontainerapps.io"
$h = Invoke-RestMethod "$base/health" -ErrorAction SilentlyContinue
# Local fallback -- only if ACA is in a rare maintenance window
if (-not $h) {
    $base = "http://localhost:8010"
    $h = Invoke-RestMethod "$base/health" -ErrorAction SilentlyContinue
    if (-not $h) {
        $env:PYTHONPATH = "C:\AICOE\eva-foundry\37-data-model"
        Start-Process "C:\AICOE\.venv\Scripts\python.exe" `
            "-m uvicorn api.server:app --port 8010 --reload" -WindowStyle Hidden
        Start-Sleep 4
    }
}
# Readiness check
$r = Invoke-RestMethod "$base/ready" -ErrorAction SilentlyContinue
if (-not $r.store_reachable) { Write-Warning "Cosmos unreachable -- check COSMOS_URL/KEY" }
# The API self-documents -- read the agent guide before doing anything
Invoke-RestMethod "$base/model/agent-guide"
# One-call state check -- all 27 layer counts + total objects
Invoke-RestMethod "$base/model/agent-summary"
```

**Azure APIM (CI / cloud agents):**
```powershell
$base = "https://marco-sandbox-apim.azure-api.net/data-model"
$hdrs = @{"Ocp-Apim-Subscription-Key" = $env:EVA_APIM_KEY}
Invoke-RestMethod "$base/model/agent-summary" -Headers $hdrs
```

#### 3.2  Query Decision Table

| You want to know... | One-turn API call | FORBIDDEN (costs 10 turns) |
|---|---|---|
| Browse all layers + objects visually | portal-face `/model` (requires `view:model` permission) | grep model/*.json |
| Report: overview / endpoint matrix / edge types | portal-face `/model/report` | build ad-hoc queries |
| All layer counts | `GET /model/agent-summary` | query each layer separately |
| Object by ID | `GET /model/{layer}/{id}` | grep, file_search |
| All objects in a layer | `GET /model/{layer}/` | read source files |
| All ready-to-call endpoints | `GET /model/endpoints/filter?status=implemented` | grep router files |
| All unimplemented stubs | `GET /model/endpoints/filter?status=stub` | grep router files |
| Filter ANY other layer | `GET /model/{layer}/` + `Where-Object` client-side | no server filter on non-endpoint layers |
| What a screen calls | `GET /model/screens/{id}` -> `.api_calls` | read screen source |
| Auth / feature flag for endpoint | `GET /model/endpoints/{id}` -> `.auth`, `.auth_mode`, `.feature_flag` | grep auth middleware |
| Where is the route handler | `GET /model/endpoints/{id}` -> `.implemented_in`, `.repo_line` | file_search |
| Cosmos container schema | `GET /model/containers/{id}` -> `.fields`, `.partition_key` | read Cosmos config |
| What breaks if container changes | `GET /model/impact/?container=X` | trace imports manually |
| Relationship graph | `GET /model/graph/?node_id=X&depth=2` | read config files |
| Services list | `GET /model/services/` -> `obj_id, status, is_active, notes` | services uses obj_id not id; no type/port |
| Is the process alive? | `GET /health` -> `.status`, `.store`, `.version` | check process list |
| Is Cosmos reachable? | `GET /health` -> `.store` == "cosmos" means Cosmos-backed | ping Cosmos directly |
| Browse all layers + objects visually | portal-face `/model` (requires `view:model` permission) | grep model/*.json |
| Report: overview stats / endpoint matrix / edge types | portal-face `/model/report` | build ad-hoc PowerShell queries |

#### 3.3  PUT Rules -- Read Before Every Write

**Rule 1 -- Capture `row_version` BEFORE mutating (not in USER-GUIDE)**
Store it before any field changes so the confirm assert can check `previous + 1`.
```powershell
$ep      = Invoke-RestMethod "$base/model/endpoints/GET /v1/tags"
$prev_rv = $ep.row_version   # capture BEFORE mutation
$ep.status         = "implemented"
```

**Rule 2 -- Strip audit columns, keep domain fields**
Exclude: `obj_id`, `layer`, `modified_by`, `modified_at`, `created_by`, `created_at`, `row_version`, `source_file`.
`is_active` is a domain field -- keep it.
```powershell
function Strip-Audit ($obj) {
    $obj | Select-Object * -ExcludeProperty `
        obj_id, layer, modified_by, modified_at, created_by, created_at, row_version, source_file
}
```

**Rule 3 -- Assign ConvertTo-Json before piping; use -Depth 10 for nested schemas**
`-Depth 5` silently truncates `request_schema` / `response_schema` objects. Always use `-Depth 10`.
```powershell
$body = Strip-Audit $ep | ConvertTo-Json -Depth 10
Invoke-RestMethod "$base/model/endpoints/GET /v1/tags" `
    -Method PUT -ContentType "application/json" -Body $body `
    -Headers @{"X-Actor"="agent:copilot"}
```

**Rule 4 -- PATCH is not supported** -- always PUT the full object (422 otherwise).

**Rule 5 -- Endpoint id = exact string "METHOD /path"** -- never construct; copy verbatim:
```powershell
Invoke-RestMethod "$base/model/endpoints/" |
    Where-Object { $_.path -like '*translations*' } | Select-Object id, path
```

#### 3.4  Write Cycle -- Every Model Change

**Preferred -- 3-step (admin/commit = export + assemble + validate in one call):**
```powershell
# Step 1 -- PUT
Invoke-RestMethod "$base/model/endpoints/GET /v1/tags" `
    -Method PUT -ContentType "application/json" -Body $body `
    -Headers @{"X-Actor"="agent:copilot"}

# Step 2 -- Canonical confirm: assert all three
$w = Invoke-RestMethod "$base/model/endpoints/GET /v1/tags"
$w.row_version   # must equal $prev_rv + 1
$w.modified_by   # must equal "agent:copilot"
$w.status        # must equal the value you PUT

# Step 3 -- Close the cycle
$c = Invoke-RestMethod "$base/model/admin/commit" `
    -Method POST -Headers @{"Authorization"="Bearer dev-admin"}
$c.status          # "PASS" = done; "FAIL" = fix violations before merging
$c.violation_count # 0 = clean
# ACA note: commit returns status=FAIL with assemble.stderr="Script not found" -- EXPECTED on ACA.
# PASS conditions on ACA: violation_count=0 AND exported_total matches agent-summary.total AND export_errors.Count=0.
```

**Manual fallback (if admin/commit unavailable):**
```
POST /model/admin/export  ->  scripts/assemble-model.ps1  ->  scripts/validate-model.ps1
[FAIL] lines block; [WARN] repo_line lines (38+) are pre-existing noise -- ignore
```

**Validate only (distinguishes new violations from pre-existing noise):**
```powershell
$v = Invoke-RestMethod "$base/model/admin/validate" `
       -Headers @{"Authorization"="Bearer dev-admin"}
$v.count       # 0 = clean; >0 = new violations to fix NOW
$v.violations  # the cross-reference FAILs -- fix these before commit
```

#### 3.5  Fix a Validation FAIL

```
Pattern: "screen 'X' api_calls references unknown endpoint 'Y'"
Root cause: api_calls used a wrong or constructed id.
```
```powershell
# Find the exact id  (never construct)
Invoke-RestMethod "$base/model/endpoints/" |
    Where-Object { $_.path -like '*conversation*' } | Select-Object id, path
# Fetch screen, replace bad id, PUT + Strip-Audit + ConvertTo-Json -Depth 10 + commit
```

#### 3.6  What to Update for Each Source Change

| Source change | Model layers to update |
|---|---|
| New FastAPI endpoint | `endpoints` + `schemas` |
| Stub -> implemented | `endpoints` -- set `status`, `implemented_in`, `repo_line` |
| New Cosmos container/field | `containers` |
| New React screen | `screens` + `literals` |
| New i18n key | `literals` |
| New hook / component | `hooks` / `components` |
| New persona / feature flag | `personas` + `feature_flags` |
| New Azure resource | `infrastructure` |
| New agent | `agents` |

> **Same-PR rule**: every source change that affects a model object must update the model
> in the same commit. Never defer. A stale model is worse than no model.

---

### 4. Encoding and Output Safety

**Windows Enterprise Encoding (cp1252) -- ABSOLUTE RULE**

```python
# [FORBIDDEN] -- causes UnicodeEncodeError in enterprise Windows
print("success")   # with any emoji or unicode

# [REQUIRED] -- ASCII only
print("[PASS] Done")   print("[FAIL] Failed")   print("[INFO] Wait...")
```

- All Python scripts: `PYTHONIOENCODING=utf-8` in any .bat wrapper
- All PowerShell output: `[PASS]` / `[FAIL]` / `[WARN]` / `[INFO]` -- never emoji
- Machine-readable outputs (JSON, YAML, evidence files): ASCII-only always
- Markdown docs (README, STATUS, PLAN, ACCEPTANCE, copilot-instructions): ASCII-only -- no emoji anywhere

---

### 5. Context Health Protocol

Maintain a mental count of Do steps (file edits, terminal commands, test runs) this session.

| Milestone | Action |
|---|---|
| Step 5  | Context health check -- answer 4 questions from memory, verify against state files |
| Step 10 | Health check + re-read SESSION-STATE.md or STATUS.md |
| Step 15 | Health check + re-read + state summary aloud |
| Every 5 after | Repeat step-10 pattern |

**4 health questions:**
1. What is the active task and its one-line description?
2. What was the last recorded test count?
3. What file am I currently editing or about to edit?
4. Have I run any terminal command I cannot account for?

**Drift signals** -- trigger immediate check:
- About to search for a file already read this session
- About to run the full test suite without isolating the failing test first
- Proposing an approach that contradicts a decision in PLAN.md
- Uncertainty about which task or sprint is active

**Recovery**: re-read STATUS.md from disk -> run baseline tests -> resume from last verified state.

---

### 6. Python Environment

```
venv exec: C:\AICOE\.venv\Scripts\python.exe
activate:  C:\AICOE\.venv\Scripts\Activate.ps1
```

Never use bare `python` or `python3`. Always use the full venv path.

---

### 7. Azure Account Pattern

- **Personal**: `{PERSONAL_SUBSCRIPTION_NAME}` -- sandbox experiments
- **Professional**: `{PROFESSIONAL_EMAIL}` -- Government of Canada / production resources
  - Dev subscription:  `{DEV_SUBSCRIPTION_ID}`
  - Prod subscription: `{PROD_SUBSCRIPTION_ID}`

If `az` fails with "subscription doesn't exist":
```powershell
az account show --query user.name
az logout; az login --use-device-code --tenant {TENANT_ID}
```

---

## PART 2 -- PROJECT-SPECIFIC

### Project Lock

This file is the copilot-instructions for **47-eva-mti** (47-eva-mti).

The workspace-level bootstrap rule "Step 1 -- Identify the active project from the currently open file path"
applies **only at the initial load of this file** (first read at session start).
Once this file has been loaded, the active project is locked to **47-eva-mti** for the entire session.
Do NOT re-evaluate project identity from editorContext or terminal CWD on each subsequent request.
Work state and sprint context are read from `STATUS.md` and `PLAN.md` at bootstrap -- not from this file.

---

---

### Project Identity

**Name**: EVA Machine Trust Index
**Folder**: `C:\AICOE\eva-foundry\47-eva-mti`
**ADO Epic**: To be created (see 19-ai-gov ADO artifacts for governance epics)
**37-data-model record**: `GET /model/projects/47-eva-mti`
**Maturity**: poc
**Phase**: Design complete (inherited from 19-ai-gov). Implementation not started (Phase 5 in PLAN.md).

**Depends on**:
- `37-data-model` (port 8010) -- `actor_trust_scores` container schema; use PUT write cycle for any schema change
- `19-ai-gov` -- governance policy layer; Decision Engine step 5 calls this project's Trust Service
- `28-rbac` -- role assignment data feeds ITI subscore
- `33-eva-brain-v2` -- emits BTI and ARI signals via `POST /trust/signal`
- `36-red-teaming` -- red team evaluation results feed ARI subscore
- `17-apim` -- injects STI signals (prompt injection, anomaly headers)
- `40-eva-control-plane` -- emits ETI signals when evidence packs are validated

**Consumed by**:
- `19-ai-gov` Decision Engine -- calls `POST /trust/evaluateTrust` at pipeline step 5
- `33-eva-brain-v2` -- reads MTI trust band before executing high-risk intents
- `31-eva-faces` -- reads trust band for Trust Indicator UI component

---

### Stack and Conventions (Target -- Implementation Phase)

```
Python 3.11+ / C:\AICOE\.venv\Scripts\python.exe
FastAPI (Trust Service HTTP surface)
Azure Cosmos DB (actor_trust_scores container)
Azure Entra ID (bearer auth on all endpoints)
```

Current state: **specification only** -- no runnable code yet. Reference specs are in `19-ai-gov` (source copies).

**Spec quality warning**: YAML blocks in `eva-mti-compute-specs.md` and `eva-mti-trust-service-api.md` (in 19-ai-gov) contain `&nbsp;` HTML entities -- they are NOT parse-ready YAML. Strip entities before using in code (M-09 task in PLAN.md).

---

### Test Command

```powershell
# No tests yet -- implementation not started
# When Trust Service is implemented:
# C:\AICOE\.venv\Scripts\python -m pytest tests/ -v --tb=short
```

**Current test count**: 0 -- implementation not started (as of 2026-02-23)

---

### Key Commands

```powershell
# Query project record
Invoke-RestMethod "$base/model/projects/47-eva-mti"

# When implementation begins -- start Trust Service locally:
# Set-Location "C:\AICOE\eva-foundry\47-eva-mti"
# C:\AICOE\.venv\Scripts\python -m uvicorn trust_service.main:app --port 8030 --reload

# Reference specs (in 19-ai-gov):
# C:\AICOE\eva-foundry\19-ai-gov\eva-mti-compute-specs.md
# C:\AICOE\eva-foundry\19-ai-gov\eva-mti-trust-service-api.md
# C:\AICOE\eva-foundry\19-ai-gov\eva-mti-scope.md
# C:\AICOE\eva-foundry\19-ai-gov\eva-mti-actions-matrix.md
```

---

### Critical Patterns

1. **Trust Service is stateless per request, stateful via Cosmos** -- each `/evaluateTrust` call reads signals from live data sources, computes all 6 subscores, writes result to `actor_trust_scores`, and returns synchronously. No in-memory actor state.

2. **Hard fail safe on missing signals** -- if a required signal source is unavailable, apply the configured `unknown_signal_penalty` (default -5 per missing signal). Never silently default to 0 (trust inflation risk).

3. **Signal ingestion is async** -- `POST /trust/signal` returns 202 immediately and queues a recompute job. The recompute must complete within 60 seconds (AC-T04). Use a background task or queue (e.g., Azure Service Bus or asyncio task).

4. **Exponential decay on BTI negatives** -- violation events must be timestamped and decayed at compute time: `weight(t) = exp(-ln(2) * t / 14)`. Never store decayed scores -- always recompute from raw events.

5. **Actor type determines weight table** -- HUMAN, AGENT, SERVICE, SYSTEM each have distinct subscore weights. ARI weight is 0 for SERVICE/SYSTEM actors. Always look up the actor type before applying the formula.

---

### Known Anti-Patterns

| Do NOT | Do instead |
|---|---|
| Store pre-decayed BTI scores in Cosmos | Store raw violation events with timestamps; decay at compute time |
| Default missing signals to 0 (zero = perfect) | Apply `unknown_signal_penalty` per missing required signal |
| Use the same weight table for HUMAN and AGENT | Look up actor type; use actor-type-specific weight table |
| Return HTTP 404 for unknown actorId on `/evaluateTrust` | Compute score with defaults/penalties; always return 200 with score |
| Use `&nbsp;` YAML blocks from spec files as-is | Strip HTML entities before using in code (M-09) |
| Expose raw numeric MTI scores in API logs | Log trust band label; raw scores only in Cosmos and secure audit trail |

---

### Skills in This Project

| Skill file | Trigger phrases | Purpose |
|---|---|---|
| `00-skill-index.skill.md` | list skills, what can you do, skill menu | Skill index (additional skills to be added during implementation) |

---

### 37-data-model -- This Project's Entities

```powershell
# Project record
Invoke-RestMethod "$base/model/projects/47-eva-mti"

# actor_trust_scores container (to be registered when implementation begins)
# Invoke-RestMethod "$base/model/containers/actor_trust_scores"

# Trust Service endpoints (to be registered when API is built):
# POST /trust/evaluateTrust
# GET  /trust/getActorTrust/{actorId}
# POST /trust/getDecision
# POST /trust/signal
```

---

### Trust Service API Quick Reference

| Endpoint | Method | Purpose | Key inputs | Key outputs |
|---|---|---|---|---|
| `/trust/evaluateTrust` | POST | Compute 6 subscores + composite MTI | Context envelope (actorId, actorType, ...) | iti, bti, cti, eti, sti, ari, compositeMti, trustBand |
| `/trust/getActorTrust/{actorId}` | GET | Current + historical scores for actor | actorId, ?history=true | Latest scores + time series |
| `/trust/getDecision` | POST | Full governance decision (chains to 19-ai-gov) | Context envelope | decision, obligations[], reasons[] |
| `/trust/signal` | POST | Ingest trust signal event | signalType, actorId, value, timestamp | 202 Accepted |

**Trust Bands:**

| Band | Score | Decision Engine allows |
|---|---|---|
| HIGH TRUST | 85-100 | Fully autonomous |
| TRUSTED | 70-84 | Allowed with monitoring |
| GUARDED | 50-69 | Human approval for sensitive |
| LOW TRUST | 30-49 | Heavily restricted |
| UNTRUSTED | 0-29 | Blocked |

---

## PART 3 -- QUALITY GATES

All must pass before merging a PR:

- [ ] Test command exits 0
- [ ] `validate-model.ps1` exits 0 (if any model layer was changed)
- [ ] No [FORBIDDEN] encoding patterns in new code
- [ ] STATUS.md updated with session summary
- [ ] PLAN.md reflects actual remaining work
- [ ] If new screen / endpoint / component added: model PUT + write cycle closed

---

*Source template*: `C:\AICOE\eva-foundry\07-foundation-layer\02-design\artifact-templates\copilot-instructions-template.md` v3.2.0
*Project 07 README*: `C:\AICOE\eva-foundry\07-foundation-layer\README.md`
*EVA Data Model USER-GUIDE*: `C:\AICOE\eva-foundry\37-data-model\USER-GUIDE.md`
