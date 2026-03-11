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

Assess and optimize data for AI workloads across platforms. Pick a workload profile, point it at your schema, and get a scored report across the six factors of AI-ready data, with guided steps to making your data AI-ready.

### Quick Start

Point your coding agent at this repo and say:

> Assess my [data assets] for RAG readiness.

The agent asks your platform and scope, loads the RAG workload profile, runs checks, and presents a scored report. From there you can drill into failures and remediate stage-by-stage.

#### Install as a skill

```bash
npx skills add Snowflake-Labs/ai-ready-data -a cortex
```

#### Standalone

Clone or add this repo as workspace context. The agent reads `skills/ai-ready-data/SKILL.md` automatically.

### How It Works

1. **Choose a platform** — Snowflake, Databricks, AWS, or Azure
2. **Discovery** — tell the agent your database, schema, and tables
3. **Choose a workload** — RAG, feature serving, training, agents, full assessment, or pick specific requirements
4. **Adjust** — skip, set, or add requirements before running
5. **Coverage** — see what's runnable on your platform before executing
6. **Assess** — platform-specific checks score each requirement 0–1
7. **Remediate** — for failures, the agent presents platform-specific fixes for your approval

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

### Built-In Workload Profiles

| Workload | Requirements | Best For |
|---|---|---|
| **rag** | 27 | Retrieval-augmented generation — chunking, embeddings, vector search, document governance |
| **feature-serving** | 39 | Online feature stores — low-latency lookups, materialized features, freshness SLAs |
| **training** | 50 | Fine-tuning and ML training — temporal integrity, reproducibility, bias testing, licensing |
| **agents** | 37 | Text-to-SQL and agentic tool use — highest bar on schema documentation, strong audit trail |

Each workload profile selects a different subset of the 61 total requirements, with thresholds tuned for the workload. Every assessment uses the same six stages.

### Overrides

Before running, you can adjust any workload profile on the fly:

- **`skip <requirement>`** — exclude a check entirely
- **`set <requirement> <threshold>`** — override a threshold
- **`add <requirement> <threshold>`** — include a check not in the base profile

For repeatability, save overrides as a custom workload profile using `extends`:

```yaml
name: my-rag-profile
extends: rag
overrides:
  skip:
    - embedding_coverage
  set:
    chunk_readiness: { min: 0.70 }
  add:
    row_access_policy: { min: 0.50 }
```

### Key Concepts

- **Workload Profile** — A YAML file selecting requirements and thresholds for a workload, organized into the six factor stages. Four built-in, unlimited custom.
- **Assessment** — The ephemeral runtime compilation of workload profile + platform + scope. Not a file.
- **Stage** — One per factor: Clean, Contextual, Consumable, Current, Correlated, Compliant.
- **Requirement** — A single testable dimension with platform-specific check (returns 0–1 score), diagnostic (detail drill-down), and fix (remediation).
- **Platform Reference** — Everything the agent needs to operate on a specific platform: capabilities, nuances, permissions, dialect notes.
- **Override** — skip/set/add adjustments applied before running an assessment.

### Extending

#### Adding a Requirement

1. Create `requirements/{name}/` directory with `requirement.yaml` (canonical metadata).
2. Add platform files under `requirements/{name}/{platform}/` — at minimum `check.sql`.
3. Add the requirement to relevant workload profile YAML(s) under the matching factor stage.

#### Adding a Workload Profile

Create `workloads/{name}.yaml` with six stages, or use `extends` to derive from an existing one.

#### Adding a Platform

1. Create `platforms/{PLATFORM}.md` covering capabilities, dialect, permissions, and nuances.
2. Add requirement files under `requirements/{key}/{platform}/`.

### Demo

See [`demo/DEMO.md`](demo/DEMO.md) for a full walkthrough: provision a demo dataset with intentional issues, run an assessment, explore diagnostics, remediate, and verify.

## Structure

```
factors/                            ← The six factors of AI-ready data (prose + requirements)
skills/
  ai-ready-data/
    SKILL.md                        ← Generic orchestration protocol
    platforms/                      ← Platform references
      {PLATFORM}.md                 ← Capabilities, nuances, permissions, dialect
    requirements/                   ← One directory per requirement (61 total)
      index.yaml                    ← Requirement registry
      {requirement_key}/
        requirement.yaml            ← Canonical metadata
        {platform}/
          check.sql               ← Platform check query (read-only)
          diagnostic.sql          ← Platform detail query (read-only)
          fix.*.sql               ← Platform remediation queries (mutating)
    workloads/                      ← Workload profiles
      rag.yaml
      feature-serving.yaml
      training.yaml
      agents.yaml
```

## Contributors

[CONTRIBUTOR LIST]

## License

All content and images are licensed under a <a href="https://creativecommons.org/licenses/by-sa/4.0/">CC BY-SA 4.0 License</a>

Code is licensed under the <a href="https://www.apache.org/licenses/LICENSE-2.0">Apache 2.0 License</a>
