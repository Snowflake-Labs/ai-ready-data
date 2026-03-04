# AI-Ready Data Skills

Assess and optimize Snowflake data for AI workloads.

## Quick Start

Point your coding agent at this repo and say:

> Assess my database for RAG readiness. I'm connected to MY_DB.MY_SCHEMA.

The agent discovers your schema, runs checks, presents results by stage, and offers to fix what's failing.

### Install as a skill

```bash
npx skills add your-org/ai-ready-data -a cortex
```

### Standalone

Clone or add this repo as workspace context. The agent reads `skills/ai-ready-data/SKILL.md` automatically.

## What It Does

1. **Discovers** your schema (database, tables, row counts)
2. **Assesses** data against a workload assessment (RAG, feature serving, training, or agents) — runs read-only SQL checks
3. **Reports** scores grouped by the six factors of AI-ready data with pass/fail status
4. **Remediates** failing requirements stage-by-stage with your approval
5. **Verifies** improvements by re-running checks

All operations are SQL — no Python, no packages, no infrastructure.

## Structure

```
skills/
  ai-ready-data/
    SKILL.md                ← Entry point for coding agents
    requirements/           ← One YAML per requirement (61 total)
    sql/
      check/                ← Assessment queries (read-only)
      diagnostic/           ← Detail queries (read-only)
      fix/                  ← Remediation queries (mutating)
    assessments/
      rag.yaml              ← RAG workload assessment
      feature-serving.yaml  ← Feature serving workload assessment
      training.yaml         ← Training workload assessment
      agents.yaml           ← Agents workload assessment
    reference/
      gotchas.md            ← Snowflake pitfalls
  build-assessment/
    SKILL.md                ← Guided assessment builder
```

## Key Concepts

- **Assessment** — A workload-specific collection of requirements with thresholds, organized into six stages. Four built-in: `rag`, `feature-serving`, `training`, `agents`. Defined in `assessments/*.yaml`.
- **Stage** — Each assessment has six stages, one per factor of AI-ready data: Clean, Contextual, Consumable, Current, Correlated, Compliant.
- **Requirement** — A single testable data quality dimension (e.g., `data_completeness`). Defined in `requirements/*.yaml` with check SQL, thresholds, and fix SQL.
- **Override** — Before running, users can `skip`, `set`, or `add` requirements to customize an assessment for their needs.

## Adding a Requirement

1. Create `requirements/{name}.yaml` with metadata, check/diagnostic/fix SQL paths, placeholders, and constraints.
2. Add SQL files to `sql/check/`, `sql/diagnostic/`, and/or `sql/fix/`.
3. Add the requirement to the relevant assessment YAML(s) under the matching factor stage.

## Adding an Assessment

Create `assessments/{name}.yaml` with six stages (Clean, Contextual, Consumable, Current, Correlated, Compliant), selecting requirements and thresholds appropriate for the workload. Alternatively, use `extends` to derive from an existing assessment with overrides.

Or say **"build me an assessment"** — the agent will interview you about your workload and generate a curated assessment YAML.
