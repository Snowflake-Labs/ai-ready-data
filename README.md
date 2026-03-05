# AI-Ready Data Agent

Assess and optimize Snowflake data for AI workloads. Pick an assessment, point it at your schema, and get a scored report across six factors of AI-ready data, with guided steps to making your data AI-ready.

## Quick Start

Point your coding agent at this repo and say:

> Assess my [data assets] for RAG readiness. 

The agent loads the RAG assessment, discovers your tables, runs checks, and presents a scored report. From there you can drill into failures, remediate stage-by-stage, or export results as JSON.

### Install as a skill

```bash
npx skills add Snowflake-Labs/ai-ready-data -a cortex
```

### Standalone

Clone or add this repo as workspace context. The agent reads `skills/ai-ready-data/SKILL.md` automatically.

## How It Works

1. **Choose an assessment** — RAG, feature serving, training, agents, or build your own
2. **Discover** — agent inventories your schema (tables, row counts, sizes)
3. **Adjust** — skip, set, or add requirements before running
4. **Assess** — read-only SQL checks score each requirement 0–1, compared against thresholds
5. **Report** — results grouped by the six factors, with pass/fail per requirement
6. **Remediate** — for failures, the agent presents fix SQL, gets your approval, executes, and verifies

All operations are SQL. No Python, no packages, no infrastructure.

## The Six Factors

Every assessment is organized into six stages — one per factor of AI-ready data:

| Factor | What It Measures | Example Requirements |
|---|---|---|
| **Clean** | Error rates — nulls, duplicates, encoding issues, schema violations | `data_completeness`, `uniqueness`, `encoding_validity` |
| **Contextual** | Schema documentation and metadata for machines and humans | `semantic_documentation`, `relationship_declaration`, `entity_identifier_declaration` |
| **Consumable** | Data in the right format, indexed, and accessible at the right latency | `embedding_coverage`, `vector_index_coverage`, `serving_latency_compliance` |
| **Current** | Freshness guarantees — change detection, SLAs, propagation latency | `change_detection`, `data_freshness`, `incremental_update_coverage` |
| **Correlated** | Lineage, provenance, and traceability from source to consumption | `data_provenance`, `lineage_completeness`, `agent_attribution` |
| **Compliant** | Governance — classification, masking, access policies, consent, retention | `classification`, `column_masking`, `access_audit_coverage` |

Clean requirements use **lower-is-better** scoring (error rates ≤ threshold). All other factors use **higher-is-better** scoring (coverage ≥ threshold).

## Built-In Assessments

| Assessment | Requirements | Best For |
|---|---|---|
| **rag** | 27 | Retrieval-augmented generation — chunking, embeddings, vector search, document governance |
| **feature-serving** | 39 | Online feature stores — low-latency lookups, materialized features, freshness SLAs |
| **training** | 50 | Fine-tuning and ML training — temporal integrity, reproducibility, bias testing, licensing |
| **agents** | 37 | Text-to-SQL and agentic tool use — highest bar on schema documentation, strong audit trail |

Each assessment selects a different subset of the 61 total requirements, with thresholds tuned for the workload. Every assessment uses the same six stages.

## Overrides

Before running, you can adjust any assessment on the fly:

- **`skip <requirement>`** — exclude a check entirely
- **`set <requirement> <threshold>`** — override a threshold
- **`add <requirement> <threshold>`** — include a check not in the base assessment

For repeatability, save overrides as a custom assessment using `extends`:

```yaml
name: my-rag-assessment
extends: rag
overrides:
  skip:
    - embedding_coverage
  set:
    chunk_readiness: { min: 0.70 }
  add:
    row_access_policy: { min: 0.50 }
```

## Build Your Own Assessment

Say **"build me an assessment"** and the agent will interview you:

1. What are you building? What data? Who consumes it?
2. Walk through each factor with pre-selected requirements based on your answers
3. Set thresholds with guidance on what the numbers mean
4. Name it, review the YAML, save it

The builder pre-selects aggressively so you approve batches, not individual items. Most users say "looks good" on 4–5 of the six factors.

## Structure

```
skills/
  ai-ready-data/
    SKILL.md                ← Agent instructions for assessment & remediation
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

- **Assessment** — A YAML file selecting requirements and thresholds for a workload, organized into the six factor stages. Four built-in, unlimited custom.
- **Stage** — One per factor: Clean, Contextual, Consumable, Current, Correlated, Compliant.
- **Requirement** — A single testable dimension with check SQL (returns 0–1 score), diagnostic SQL (detail drill-down), and fix SQL (remediation). 61 total.
- **Override** — skip/set/add adjustments applied before running an assessment.

## Extending

### Adding a Requirement

1. Create `requirements/{name}.yaml` with metadata, check/diagnostic/fix SQL paths, placeholders, and constraints.
2. Add SQL files to `sql/check/`, `sql/diagnostic/`, and/or `sql/fix/`.
3. Add the requirement to the relevant assessment YAML(s) under the matching factor stage.

### Adding an Assessment

Create `assessments/{name}.yaml` with six stages, or use `extends` to derive from an existing one. Or say **"build me an assessment"** and let the agent generate it through conversation.

## Demo

See [`demo/DEMO.md`](demo/DEMO.md) for a full walkthrough: provision a demo dataset with intentional issues, run an assessment, explore diagnostics, remediate, and verify.
