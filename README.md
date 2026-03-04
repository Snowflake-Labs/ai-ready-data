# AI-Ready Data Skills

Assess and optimize Snowflake data for AI workloads.

## Quick Start

Point your coding agent at this repo and say:

> Assess my database for AI readiness. I'm connected to MY_DB.MY_SCHEMA.

The agent discovers your schema, runs checks, presents results by stage, and offers to fix what's failing.

### Install as a skill

```bash
npx skills add your-org/ai-ready-data -a cortex
```

### Standalone

Clone or add this repo as workspace context. The agent reads `skills/ai-ready-data/SKILL.md` automatically.

## What It Does

1. **Discovers** your schema (database, tables, row counts)
2. **Assesses** data against a workload profile (serving or training) — runs read-only SQL checks
3. **Reports** scores grouped by stage with pass/fail status
4. **Remediates** failing requirements stage-by-stage with your approval
5. **Verifies** improvements by re-running checks

All operations are SQL — no Python, no packages, no infrastructure.

## Structure

```
skills/ai-ready-data/
  SKILL.md                ← Entry point for coding agents
  requirements/           ← One YAML per requirement (60 total)
  sql/
    check/                ← Assessment queries (read-only)
    diagnostic/           ← Detail queries (read-only)
    fix/                  ← Remediation queries (mutating)
  profiles/
    serving.yaml          ← Serving workload thresholds
    training.yaml         ← Training workload thresholds
  reference/
    gotchas.md            ← Snowflake pitfalls
```

## Key Concepts

- **Requirement** — A single testable data quality dimension (e.g., `data_completeness`). Defined in `requirements/*.yaml` with check SQL, thresholds, and fix SQL.
- **Profile** — A workload definition listing which requirements to check and at what thresholds. Two built-in: `serving` and `training`. Defined in `profiles/*.yaml`.
- **Factor** — Requirements are grouped into 6 factors: clean, contextual, consumable, current, correlated, compliant.

## Adding a Requirement

1. Create `requirements/{name}.yaml` with metadata, check/diagnostic/fix SQL paths, placeholders, and constraints.
2. Add SQL files to `sql/check/`, `sql/diagnostic/`, and/or `sql/fix/`.
3. Add the requirement to the relevant profile YAML with a threshold.

## Adding a Profile

Create `profiles/{name}.yaml` with stages, requirements, and thresholds. See `profiles/serving.yaml` for the format.
