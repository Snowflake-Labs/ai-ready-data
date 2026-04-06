# The AI-Ready Data Framework

## Introduction

The **AI-Ready Data Framework** is an open standard that defines what "AI-ready" actually means. The six factors of AI-ready data provide criteria and requirements to help you evaluate your data, pipelines, and platforms against the demands of AI workloads.

This repo contains two things:

1. **The framework** — six factors, 62 measurable requirements, and five workload profiles that define AI-readiness as a platform-agnostic standard.
2. **The `ai-ready-data` skill** — an installable agent skill that can scan your data estate, assess specific assets against a profile, score every requirement, and guide you through remediation. Point a coding agent at this repo and say "assess my data for RAG readiness" — it handles the rest.

Use the framework to understand what matters. Use the skill to measure where you stand and fix what doesn't pass.

### Background

The contributors to this framework include practicing data engineers, ML engineers, and platform architects who have built and operated AI systems across industries.

This repo synthesizes our collective experience building data infrastructure that can reliably power AI. Our goal is to help data practitioners design infrastructure that produces trustworthy AI decisions.

### Who should use this repo?

- **Data engineers** building pipelines that power AI systems.
- **Platform teams** designing infrastructure for ML and AI workloads.
- **Architects** evaluating whether their stack can support RAG, agents, or real-time inference.
- **Data leaders** who need to assess organizational AI readiness and communicate gaps to their teams.
- **Coding agents** building the data infrastructure they will eventually consume.

## The Six Factors of AI-Ready Data

1. **[Clean](factors/0-clean.md)**: Clean data is consistently accurate, complete, valid, and free of errors that would compromise downstream consumption.
2. **[Contextual](factors/1-contextual.md)**: Meaning is explicit and colocated with the data. No external lookup, tribal knowledge, or human context is required to take action on the data.
3. **[Consumable](factors/2-consumable.md)**: Data is served in the right format and at the right latencies for AI workloads.
4. **[Current](factors/3-current.md)**: Data reflects the present state, with freshness enforced by infrastructure rather than assumed by convention.
5. **[Correlated](factors/4-correlated.md)**: Data is traceable from source to every decision it informs.
6. **[Compliant](factors/5-compliant.md)**: Data is governed with explicit ownership, enforced access boundaries, and AI-specific safeguards.

These factors apply to any data system powering AI applications, regardless of tech stack.

### Requirements

Each factor is backed by a set of measurable **requirements** — specific, platform-agnostic criteria that define what must be true of your data. Requirements describe the *what*, not the *how*. The full canonical list lives in the [skill manifest](skills/ai-ready-data/requirements/requirements.yaml).

The factor markdown files above describe the *why* and *what* of each factor in prose. The manifest provides the machine-readable counterpart: every requirement has a unique key, a description, a factor, and a scope (schema, table, or column). All tests return a normalized score between 0 and 1, making it straightforward to build automated assessments or dashboards on top of the framework.

## AI-Ready Data Skill

An installable skill that any coding agent can dynamically load and execute. Scan your data estate for prioritization, assess specific assets against a profile, and get a scored report across the six factors of AI-ready data with guided remediation.

### Quick Start

#### Install as a skill

```bash
npx skills add Snowflake-Labs/ai-ready-data -a cortex
```

#### Standalone

Clone or add this repo as workspace context. The agent reads `skills/ai-ready-data/SKILL.md` automatically.

#### Start assessment

After installing, ask your coding agent:

> Assess my [data assets] for RAG readiness.

The agent asks your platform and scope, loads the RAG profile, runs checks, and presents a scored report. From there you can drill into failures and remediate stage-by-stage.

For estate-level prioritization:

> Scan my data estate for AI readiness.

The agent sweeps across all schemas in a database with lightweight readiness proxies and presents a comparative ranking.


### How It Works

Three phases, from light to deep: Scan, Assess, Remediate.

1. **Choose a platform**: Snowflake, Postgres, etc
2. **Discovery**: tell the agent your database, schema, and tables, or scan your entire estate
3. **Choose a profile**: RAG, feature serving, training, agents, full assessment, or pick specific requirements
4. **Adjust**: skip, set, or add requirements before running
5. **Coverage**: see what's runnable on your platform before executing
6. **Assess**: platform-specific checks score each requirement 0–1
7. **Remediate**: for failures, the agent presents platform-specific fixes for your approval

### Factor Stages

Every assessment is organized into six stages, one per factor of AI-ready data:


| Factor         | Example Requirements                                                                  |
| -------------- | ------------------------------------------------------------------------------------- |
| **Clean**      | `data_completeness`, `uniqueness`, `referential_integrity`                            |
| **Contextual** | `semantic_documentation`, `relationship_declaration`, `entity_identifier_declaration` |
| **Consumable** | `embedding_coverage`, `vector_index_coverage`, `serving_latency_compliance`           |
| **Current**    | `change_detection`, `data_freshness`, `incremental_update_coverage`                   |
| **Correlated** | `data_provenance`, `lineage_completeness`, `agent_attribution`                        |
| **Compliant**  | `classification`, `column_masking`, `access_audit_coverage`                           |


All scores are 0–1 where **1.0 is perfect**. Requirements pass when `score >= threshold`.

### Built-In Profiles


| Profile             | Requirements | Best For                                                                                     |
| ------------------- | ------------ | -------------------------------------------------------------------------------------------- |
| **scan**            | 8            | Estate-level sweep: lightweight readiness proxies for portfolio analysis and prioritization |
| **rag**             | 27           | Retrieval-augmented generation: chunking, embeddings, vector search, document governance    |
| **feature-serving** | 39           | Online feature stores: low-latency lookups, materialized features, freshness SLAs           |
| **training**        | 50           | Fine-tuning and ML training: temporal integrity, reproducibility, bias testing, licensing   |
| **agents**          | 37           | Text-to-SQL and agentic tool use: highest bar on schema documentation, strong audit trail   |


Each profile selects a different subset of the total requirements, with thresholds tuned for the use case. Every assessment uses the same six stages.

### Overrides

Before running, you can adjust any profile on the fly:

- **`skip <requirement>`**: exclude a check entirely
- **`set <requirement> <threshold>`**: override a threshold
- **`add <requirement> <threshold>`**: include a check not in the base profile

For repeatability, save overrides as a custom profile using `extends`:

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

- **Factor**: one of six categories of AI-ready data (Clean, Contextual, Consumable, Current, Correlated, Compliant). Factors define the dimensions along which data is evaluated.
- **Requirement**: a platform-agnostic criterion that must be true of the data. Requirements define *what* to measure, not *how*. All requirements live in a single manifest (`requirements/requirements.yaml`).
- **Check**: a platform-specific markdown file (`check.md`) containing prose context and SQL that measures a requirement, returning a normalized 0–1 score. Context, constraints, and variant guidance are co-located directly above the SQL they apply to.
- **Diagnostic**: a platform-specific markdown file (`diagnostic.md`) containing prose context and SQL that provides detail drill-downs on check results.
- **Fix**: a platform-specific markdown file (`fix.md`) containing remediation options — executable SQL and/or organizational process guidance. A single file can contain multiple remediation paths with prose explaining when to use each. Fixes are executed only with explicit user approval.
- **Profile**: a curated collection of requirements with thresholds, organized into the six factor stages. Profiles can target a workload (RAG, training, feature-serving, agents) or an estate-level scan. Five built-in, unlimited custom.
- **Assessment**: the guided flow where the agent discovers scope and profile, runs tests, and produces a scored report.
- **Scan**: estate-level sweep using the lightweight scan profile across many schemas for comparative prioritization. Scans turn into assessments when the user drills into a specific schema.
- **Platform Reference**: everything the agent needs to operate on a specific platform, including capabilities, nuances, permissions, and dialect notes.
- **Override**: skip/set/add adjustments applied to a profile before running an assessment.

### Extending

#### Adding a Requirement

1. Add an entry to `requirements/requirements.yaml` with: description, factor, scope, placeholders, implementations.
2. Create `requirements/{name}/{platform}/` with three markdown files:
   - `check.md` (required) — context + SQL returning a `value` score 0–1
   - `diagnostic.md` (required) — context + SQL for detail drill-down
   - `fix.md` (required) — remediation SQL and/or organizational guidance
3. Add the requirement to relevant profile YAML(s) under the matching factor stage.

#### Adding a Profile

Create `profiles/{name}.yaml` with six stages, or use `extends` to derive from an existing one.

#### Adding a Platform

1. Create `platforms/{PLATFORM}.md` covering capabilities, dialect, permissions, and nuances.
2. Add requirement files under `requirements/{key}/{platform}/`.

### Demos

See [`demos/README.md`](demos/README.md) for available demo walkthroughs. Start with **Scan + Agents** for the full estate scan → deep assessment → remediation flow, or **RAG Readiness** for a focused single-schema assessment.

## Structure

```
factors/                            # The six factors of AI-ready data (prose + requirements)
skills/
  ai-ready-data/
    SKILL.md                        # Orchestration protocol (Scan, Assess, Remediate)
    platforms/                      # Platform references
      {PLATFORM}.md                 # Capabilities, nuances, permissions, dialect
    requirements/                   # Requirement manifest + implementation directories
      requirements.yaml             # Single manifest (all requirement metadata)
      {requirement_key}/
        {platform}/
          check.md                # Context + check SQL (read-only, returns 0–1 score)
          diagnostic.md           # Context + diagnostic SQL (read-only detail)
          fix.md                  # Context + remediation SQL/guidance (mutating)
    profiles/                       # Assessment profiles
      scan.yaml                     # Estate-level scan (lightweight)
      rag.yaml
      feature-serving.yaml
      training.yaml
      agents.yaml
```

## Contributors

<!-- CONTRIBUTORS:START -->
<table>
  <tr>
    <td align="center">
      <a href="https://github.com/jacobprall">
        <img src="https://github.com/jacobprall.png" width="80px;" alt="jacobprall"/>
        <br /><sub><b>Jacob Prall</b></sub>
      </a>
    </td>
    <td align="center">
      <a href="https://github.com/rajivgupta780184">
        <img src="https://github.com/rajivgupta780184.png" width="80px;" alt="rajivgupta780184"/>
        <br /><sub><b>Rajiv Gupta</b></sub>
      </a>
    </td>
  </tr>
</table>
<!-- CONTRIBUTORS:END -->

## License

All content and images are licensed under a [CC BY 4.0 License](https://creativecommons.org/licenses/by/4.0/)

Code is licensed under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0)