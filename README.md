# The AI-Ready Data Framework

<div align="center">
<a href="https://www.apache.org/licenses/LICENSE-2.0">
        <img src="https://img.shields.io/badge/Code-Apache%202.0-blue.svg" alt="Code License: Apache 2.0"></a>
<a href="https://creativecommons.org/licenses/by-sa/4.0/">
        <img src="https://img.shields.io/badge/Content-CC%20BY--SA%204.0-lightgrey.svg" alt="Content License: CC BY-SA 4.0"></a>

</div>

<p></p>

## Introduction

The **AI-Ready Data Framework** is an open standard that defines what "AI-ready" actually means. The six factors of AI-ready data provide criteria and requirements to help you evaluate your data, pipelines, and platforms against the demands of AI workloads. Use this framework to assess where you stand and prioritize what matters most for your specific AI ambitions.

### Background

The contributors to this framework include practicing data engineers, ML engineers, and platform architects who have built and operated AI systems across industries.

This document synthesizes our collective experience building data infrastructure that can reliably power AI. Our goal is to help data practitioners design infrastructure that produces trustworthy AI decisions.

### Who should read this document?

* **Data engineers** building pipelines that power AI systems.
* **Platform teams** designing infrastructure for ML and AI workloads.
* **Architects** evaluating whether their stack can support RAG, agents, or real-time inference.
* **Data leaders** who need to assess organizational AI readiness and communicate gaps to their teams.
* **Coding Agents** building the data infrastructure they will eventually consume

## The Six Factors of AI-Ready Data

0. [**Clean**](factors/0-clean.md) — Clean data is consistently accurate, complete, valid, and free of errors that would compromise downstream consumption.
1. [**Contextual**](factors/1-contextual.md) — Contextual data carries canonical semantics; meaning is explicit and co-located.
2. [**Consumable**](factors/2-consumable.md) — Consumable data is served in the right format and at the right latencies for AI workloads.
3. [**Current**](factors/3-current.md) — Current data reflects the present state with freshness enforced by systems, not assumed by AI consumers.
4. [**Correlated**](factors/4-correlated.md) — Correlated data is traceable from source to every decision it informs.
5. [**Compliant**](factors/5-compliant.md) — Compliant data meets regulatory requirements through enforced access controls, clear ownership, and auditable AI-specific safeguards.

These factors apply to any data system powering AI applications, regardless of tech stack.

### Requirements

Each factor is backed by a set of measurable **requirements** — specific criteria that can be evaluated against your data and platform. The full canonical list lives in [`factors/requirements.yaml`](factors/requirements.yaml).

The factor markdown files above describe the *why* and *what* of each factor in prose. The requirements file provides the machine-readable counterpart: every requirement has a unique key, a description, and a `workload` tag indicating whether it applies to `serving`, `training`, or both. All tests should be evaluated against a threshold and return a normalized score between 0 and 1, making it straightforward to build automated assessments or dashboards on top of the framework.

## AI-Ready Data Agent

Assess and optimize Snowflake data for AI workloads. Pick an assessment, point it at your schema, and get a scored report across the six factors of AI-ready data, with guided steps to making your data AI-ready.

### Quick Start

Point your coding agent at this repo and say:

> Assess my [data assets] for RAG readiness.

The agent loads the RAG assessment, discovers your tables, runs checks, and presents a scored report. From there you can drill into failures, remediate stage-by-stage, or export results as JSON.

#### Install as a skill

```bash
npx skills add Snowflake-Labs/ai-ready-data -a cortex
```

#### Standalone

Clone or add this repo as workspace context. The agent reads `skills/ai-ready-data/SKILL.md` automatically.

### How It Works

1. **Choose a platform + assessment** — platform (Snowflake, Databricks, AWS, Azure) and workload assessment (RAG, feature serving, training, agents, or custom)
2. **Discover** — agent inventories your schema (tables, row counts, sizes)
3. **Adjust** — skip, set, or add requirements before running
4. **Assess** — read-only SQL checks score each requirement 0–1, compared against thresholds
5. **Report** — results grouped by the six factors, with pass/fail per requirement
6. **Remediate** — for failures, the agent presents fix SQL, gets your approval, executes, and verifies

Checks and fixes are platform implementations with normalized outputs. SQL remains the default implementation style where supported.

### Factor Stages

Every assessment is organized into six stages — one per factor of AI-ready data:

| Factor | What It Measures | Example Requirements |
|---|---|---|
| **Clean** | Accuracy, completeness, validity, and error-free records | `data_completeness`, `uniqueness`, `referential_integrity` |
| **Contextual** | Schema documentation and metadata for machines and humans | `semantic_documentation`, `relationship_declaration`, `entity_identifier_declaration` |
| **Consumable** | Data in the right format, indexed, and accessible at the right latency | `embedding_coverage`, `vector_index_coverage`, `serving_latency_compliance` |
| **Current** | Freshness guarantees — change detection, SLAs, propagation latency | `change_detection`, `data_freshness`, `incremental_update_coverage` |
| **Correlated** | Lineage, provenance, and traceability from source to consumption | `data_provenance`, `lineage_completeness`, `agent_attribution` |
| **Compliant** | Governance — classification, masking, access policies, consent, retention | `classification`, `column_masking`, `access_audit_coverage` |

All scores are 0–1 where **1.0 is perfect**. Requirements pass when `score >= threshold`.

### Built-In Assessments

| Assessment | Requirements | Best For |
|---|---|---|
| **rag** | 27 | Retrieval-augmented generation — chunking, embeddings, vector search, document governance |
| **feature-serving** | 39 | Online feature stores — low-latency lookups, materialized features, freshness SLAs |
| **training** | 50 | Fine-tuning and ML training — temporal integrity, reproducibility, bias testing, licensing |
| **agents** | 37 | Text-to-SQL and agentic tool use — highest bar on schema documentation, strong audit trail |

Each assessment selects a different subset of the 61 total requirements, with thresholds tuned for the workload. Every assessment uses the same six stages.

### Overrides

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

### Build Your Own Assessment

Say **"build me an assessment"** and the agent will interview you:

1. What are you building? What data? Who consumes it?
2. Walk through each factor with pre-selected requirements based on your answers
3. Set thresholds with guidance on what the numbers mean
4. Name it, review the YAML, save it

### Key Concepts

- **Assessment** — A YAML file selecting requirements and thresholds for a workload, organized into the six factor stages. Four built-in, unlimited custom.
- **Stage** — One per factor: Clean, Contextual, Consumable, Current, Correlated, Compliant.
- **Requirement** — A single testable dimension with check SQL (returns 0–1 score), diagnostic SQL (detail drill-down), and fix SQL (remediation). 
- **Override** — skip/set/add adjustments applied before running an assessment.

### Extending

#### Adding a Requirement

1. Create `requirements/{name}/` directory with `requirement.yaml` (canonical metadata) and add platform implementations under `implementations/{platform}/`.
2. For each supported platform, add at minimum `check.sql`, and optionally `diagnostic.sql` and `fix.{name}.sql`.
3. Add the requirement to the relevant assessment YAML(s) under the matching factor stage.

#### Adding an Assessment

Create `assessments/{name}.yaml` with six stages, or use `extends` to derive from an existing one. Or say **"build me an assessment"** and let the agent generate it through conversation.

### Demo

See [`demo/DEMO.md`](demo/DEMO.md) for a full walkthrough: provision a demo dataset with intentional issues, run an assessment, explore diagnostics, remediate, and verify.

## Structure

```
factors/                            ← The six factors of AI-ready data (prose + requirements)
skills/
  ai-ready-data/
    SKILL.md                        ← Agent instructions for assessment & remediation
    platforms/                      ← Platform capability manifests + platform gotchas
      snowflake/
        capabilities.yaml
        gotchas.md
      databricks/
        capabilities.yaml
        gotchas.md
      aws/
        capabilities.yaml
        gotchas.md
      azure/
        capabilities.yaml
        gotchas.md
    requirements/                   ← One directory per requirement (61 total)
      index.yaml                    ← Requirement registry for deterministic discovery
      data_completeness/
        requirement.yaml            ← Metadata (no SQL paths)
        implementations/
          snowflake/
            check.sql               ← Platform assessment query (read-only)
            diagnostic.sql          ← Platform detail query (read-only)
            fix.*.sql               ← Platform remediation queries (mutating)
      ...
    assessments/
      rag.yaml                      ← RAG workload assessment
      feature-serving.yaml          ← Feature serving workload assessment
      training.yaml                 ← Training workload assessment
      agents.yaml                   ← Agents workload assessment
    reference/
      gotchas.md                    ← Snowflake pitfalls
  build-assessment/
    SKILL.md                        ← Guided assessment builder
```

## Contributors

[CONTRIBUTOR LIST]

## License

All content and images are licensed under a <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0 License</a>

Code is licensed under the <a href="https://www.apache.org/licenses/LICENSE-2.0">Apache 2.0 License</a>
