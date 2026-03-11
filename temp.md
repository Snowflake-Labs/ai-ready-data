# Architecture Refactor Plan — Multi-Platform AI-Ready Data Framework

## Core Mental Model

The framework has five distinct layers. Each has a clear role and clean boundaries.

### Factors

The six categories of AI-ready data: Clean, Contextual, Consumable, Current, Correlated, Compliant.

- Purely organizational taxonomy
- Nothing executes at this layer
- Every requirement belongs to exactly one factor
- Every assessment uses all six as stages

### Requirements

Platform-agnostic testable claims about data quality.

- Each requirement says "this thing must be true about AI-ready data"
- Declares: name, description, factor, workload tags, scope, placeholders, constraints
- `workload` tags indicate which workload profiles the requirement is relevant to
- Requirements do not know about platforms — they define *what* to measure, not *how*

### Workload Profiles

Curated selections of requirements with thresholds, stored as YAML files (`rag.yaml`, `training.yaml`, etc.).

- Organized into six stages (one per factor)
- Select a subset of the 61 total requirements
- Set thresholds per requirement (`min: 0.90`)
- Provide a `why` per stage for user context
- **Thresholds live here** — the workload defines what "good" looks like, not the platform
- Platform-agnostic: the same profile applies regardless of where the data lives
- Overrides (`skip`, `set`, `add`) customize a profile for a specific run
- Users can also select "full assessment" (all 61 requirements) or hand-pick from the catalog

### Platform Packs

Everything needed to execute on a specific platform.

- Capability manifest — a markdown doc explaining what the platform supports, how it works, and what to watch out for (replaces the boolean `capabilities.yaml` + separate gotchas)
- Per-requirement implementations live in `requirements/{key}/implementations/{platform}/`

### Assessments

**Assessments are ephemeral.** An assessment is not a file — it is the runtime compilation of:

```
workload profile + platform + scope = assessment
```

The agent assembles the assessment at runtime by:

1. Loading the workload profile (requirements + thresholds)
2. Intersecting with the platform's available implementations
3. Scoping to the user's database/schema/tables
4. Producing a runnable plan with clear coverage transparency

Assessments are not persisted or versioned. The workload profiles are the durable artifacts.

---

## Conversation Flow

The agent-user interaction follows this sequence:

```
1. Platform        → user selects platform
2. Discovery       → conversational: agent asks about database, schema, tables
3. Workload        → user picks a workload profile or selects requirements manually
4. Adjustments     → apply overrides (skip/set/add)
5. Coverage        → show what's runnable vs N/A before executing
6. Assess          → execute checks, score, report
7. Remediate       → platform-specific fixes for failures
```

Key design points:

- **Platform is explicit.** User must select their platform. No auto-detection for now. One assessment, one platform.
- **Discovery is conversational.** Discovery is the process of getting scope details from the user (database, schema, tables) — not a SQL execution step. The agent asks, the user answers. Platform-specific querying happens during the assess phase.
- **Workload selection is flexible.** User can pick a built-in workload profile, say "full assessment" for all requirements, or hand-pick from the requirement catalog with the agent's help.
- **Coverage summary before execution.** Before running, the agent shows what's runnable vs N/A on the selected platform. User confirms before execution begins.
- **`N/A` is a compile-time result, not a runtime surprise.** Unsupported requirements are identified during plan assembly.

---

## Decisions Made

### D1: Semantic View Builder → extract to platform file

Extract to `platforms/snowflake/semantic-view-builder.md`. SKILL.md references it via capability gate: "if platform supports semantic views, read and follow the platform's semantic view builder."

### D2: Platform-specific nuances → per-platform markdown

Each platform gets a prose document explaining platform-specific nuances for the agent. Not called "gotchas" — needs a better name. Candidates: `platform-notes.md`, `agent-guide.md`, `nuances.md`. This replaces the current `gotchas.md` files.

This document should cover:
- What the platform supports and how it differs from others
- SQL dialect notes and behavioral quirks
- Permission model and access patterns
- Metadata visibility and latency caveats
- Anything the agent needs to know to execute correctly on this platform

### D3: Placeholders — remove the reference table

Placeholders (`{{ database }}`, `{{ schema }}`, `{{ asset }}`, etc.) are template variables in SQL files that the agent substitutes from context. The large placeholder reference table in SKILL.md is unnecessary — the agent can infer substitution values from:
- The `scope` field in `requirement.yaml` (schema, table, or column scoped)
- The SQL file itself (the `{{ }}` markers are self-documenting)
- The user's stated scope (database, schema, tables)

Remove the placeholder table from SKILL.md. Keep a brief note explaining the `{{ }}` substitution convention.

### D4: Legacy `reference/gotchas.md` → merge and delete

Merge content into `platforms/snowflake/` platform notes and delete `reference/gotchas.md`. One source of truth per platform.

### D5: Remove build-assessment skill

Remove `skills/build-assessment/` entirely for now. The workload selection conversation in the main skill handles requirement selection. Can be re-added later as a dedicated skill for building custom workload profiles.

### D6: Requirement selection — user picks what matters

Users can:
1. Pick a built-in workload profile (rag, feature-serving, training, agents)
2. Say "full assessment" to run all 61 requirements
3. Select specific requirements from the catalog with the agent's help

No compliance tiers or separate compliance profiles. Keep it simple — the user tells the agent what they care about, the agent runs it.

This means the conversation flow for workload selection might look like:
```
What would you like to assess?
  1. RAG readiness (27 requirements)
  2. Feature serving readiness (39 requirements)
  3. Training readiness (50 requirements)
  4. Agent readiness (37 requirements)
  5. Full assessment (all 61 requirements)
  6. Let me pick specific requirements
```

### D7: JSON export — remove for now

Remove JSON export from SKILL.md. Add back later with updated schema that reflects the new architecture (platform field, N/A reasons, workload terminology).

### D8: Platform selection — explicit, single platform

User must explicitly select their platform. One assessment, one platform. No auto-detection. No multi-platform in v1.

### M2: Capabilities as markdown, not YAML

Replace `capabilities.yaml` (boolean flags) with a markdown document that gives the agent rich context about platform capabilities, nuances, and caveats. This combines what was previously split across `capabilities.yaml`, `gotchas.md`, and `execution-playbook.md` into a single authoritative platform reference.

This is a significant simplification — instead of structured boolean flags that nothing actually enforces at runtime, give the agent prose it can reason about.

### M3: Discovery is conversation, not querying

Discovery is the conversational step where the agent learns the user's scope:
- What platform?
- What database/schema?
- What tables (or all)?

It is NOT a SQL execution step. Platform-specific metadata queries (table inventory, row counts, etc.) happen during the assess phase as needed. The discovery step is purely about establishing context.

---

## What Changes

### 1. Rename assessments/ to workloads/

- Rename directory
- Update all references in SKILL.md, AGENTS.md, README.md, scripts

### 2. Replace capabilities.yaml + gotchas with unified platform markdown

For each platform, replace:
- `capabilities.yaml`
- `gotchas.md`
- `execution-playbook.md` (in docs/)
- `README.md`

With a single authoritative file:
```
platforms/{platform}/PLATFORM.md
```

This file is what the agent reads to understand how to operate on this platform. It covers capabilities, nuances, permissions, dialect notes, and anything else the agent needs.

### 3. Extract Semantic View Builder from SKILL.md

Move the Semantic View Builder workflow (~250 lines) to:
```
platforms/snowflake/semantic-view-builder.md
```

SKILL.md gets a brief capability-gated reference: "If platform supports semantic views, read `platforms/{platform}/semantic-view-builder.md`."

### 4. Extract idempotency guards and delegation targets from SKILL.md

Move to platform-specific files:
```
platforms/{platform}/guards.yaml
platforms/{platform}/delegations.yaml
```

Or include in `PLATFORM.md` if the content is small enough for each platform.

### 5. Rewrite SKILL.md as generic orchestration

SKILL.md becomes the platform-agnostic orchestration protocol:

- Conversation flow (platform → discovery → workload → adjust → coverage → assess → remediate)
- Phase definitions and checkpoint behavior
- Report format
- Override mechanics
- Requirement directory convention
- Brief `{{ }}` substitution note (no full placeholder table)
- How to add requirements and workload profiles

Removed from SKILL.md:
- All Snowflake SQL
- Idempotency guard table
- Skill delegation table
- Semantic View Builder
- Snowflake gotchas section
- Required permissions table
- Placeholder reference table
- JSON export schema

### 6. Add coverage summary step

After workload + platform intersection, before execution:
```
RAG Assessment — Databricks — MY_DB.MY_SCHEMA

Selected: 27 requirements
Runnable: 24
Not available: 3 (no implementation on this platform)

Proceed?
```

### 7. Update workload selection UX

Add "full assessment" and "pick specific requirements" options alongside the four built-in workload profiles.

### 8. Remove build-assessment skill

Delete `skills/build-assessment/` and remove references from AGENTS.md and README.md.

### 9. Merge reference/gotchas.md into platform pack and delete

Content goes into `platforms/snowflake/PLATFORM.md`. Delete `reference/gotchas.md` and `reference/` directory.

### 10. Remove JSON export

Remove export schema and instructions from SKILL.md. Will be re-added later with updated schema.

### 11. Clean up straggling assessment terminology

Grep for "assessment" across all docs and scripts. Replace with "workload profile" where it refers to the YAML file, keep "assessment" where it refers to the ephemeral runtime compilation.

### 12. Update validators and CI

- Update scripts for workloads/ path rename
- Update scripts for removed capabilities.yaml (no longer validated as YAML)
- Update scripts for removed build-assessment references
- Add validation that platform PLATFORM.md exists
- Build a single comprehensive validator at the end

### 13. Sync mirrors and regenerate artifacts

- Run `sync_skill_mirrors.py`
- Regenerate `index.yaml`
- Regenerate support matrix

---

## File Structure (Target)

```
skills/
  ai-ready-data/
    SKILL.md                              ← Generic orchestration protocol (no platform SQL)
    workloads/                            ← Workload profiles (renamed from assessments/)
      rag.yaml
      feature-serving.yaml
      training.yaml
      agents.yaml
    platforms/                            ← Platform packs
      snowflake/
        PLATFORM.md                       ← Unified: capabilities, nuances, permissions, dialect
        semantic-view-builder.md          ← Snowflake-specific remediation workflow
        guards.yaml                       ← Idempotency guard patterns
        delegations.yaml                  ← Skill delegation targets
      databricks/
        PLATFORM.md
        guards.yaml
        delegations.yaml
      aws/
        PLATFORM.md
      azure/
        PLATFORM.md
    requirements/                         ← One directory per requirement (61 total)
      index.yaml                          ← Requirement registry
      {requirement_key}/
        requirement.yaml                  ← Canonical metadata (platform-agnostic)
        implementations/
          snowflake/
            check.sql
            diagnostic.sql
            fix.*.sql
            constraints.md
          databricks/
            check.sql
            diagnostic.sql
            fix.*.sql
```

Removed:
- `skills/build-assessment/` (entire skill)
- `skills/ai-ready-data/reference/` (merged into platform pack)
- `capabilities.yaml` per platform (replaced by PLATFORM.md)
- `gotchas.md` per platform (replaced by PLATFORM.md)
- Multiple docs files (consolidated)

---

## Documentation Updates

### SKILL.md

- Rewrite as generic orchestration protocol
- New conversation flow (platform → discovery → workload → adjust → coverage → assess → remediate)
- Remove all Snowflake-specific SQL, guards, delegations, gotchas, permissions
- Remove placeholder table (keep brief substitution note)
- Remove JSON export
- Add coverage summary step
- Add flexible workload selection (built-in profiles, full, or pick-your-own)
- Reference workload profiles (not assessments)
- Reference `platforms/{platform}/PLATFORM.md` for platform-specific behavior
- Gate platform-specific workflows on capabilities described in PLATFORM.md

### AGENTS.md

- Update structure diagram (workloads/, platform packs, removed build-assessment)
- Remove build-assessment references
- Update entry point description
- Clean assessment → workload profile terminology

### README.md

- Update "How It Works" to reflect new conversation flow
- Update "Structure" diagram
- Remove build-assessment references
- Update "Extending" section for platform pack requirements
- Update terminology (assessment = ephemeral, workload profile = the YAML)
- Update "Quick Start" to mention platform selection

### CONTRIBUTING.md

- Update validation commands for renamed paths
- Update contribution types (platform packs use PLATFORM.md, not capabilities.yaml)
- Remove references to build-assessment

### docs/PLATFORM_CONTRIBUTOR_SPEC.md

- `PLATFORM.md` as required platform file (replaces capabilities.yaml + gotchas.md + README.md)
- `guards.yaml` as recommended
- `delegations.yaml` as recommended
- Update PR checklist

### docs/contracts/execution-contract.md

- Update for conversational discovery model
- Update resolver pseudocode for coverage summary
- Document ephemeral assessment compilation model
- Remove JSON export references

### docs/workflows/assessment.md

- Rewrite for new flow
- Document coverage summary behavior

### docs/workflows/remediation.md

- Reference platform-specific guards and delegations
- Remove hardcoded Snowflake patterns

### docs/platforms/ (execution playbooks)

- Remove individual playbook files (consolidated into PLATFORM.md in platform packs)

### .agents/skills/

- Sync mirrors after all changes
- Remove .agents/skills/build-assessment/
