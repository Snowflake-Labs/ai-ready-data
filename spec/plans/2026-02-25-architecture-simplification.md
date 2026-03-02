# 2026-02-25 — Architecture Simplification Proposal

Refactor from layered skill-library architecture to a flat, test-framework architecture compatible with `npx skills` ecosystem.

---

## Motivation

The package does two things:

1. **Assess** data products for AI-readiness through requirements and tests, then report.
2. **Remediate** issues to make the data AI-ready.

That's a test suite with fix-it capabilities. The architecture should reflect that — not a multi-layered routing system with formal vocabulary specs.

---

## Current Architecture: What Exists

**~100 non-git files** across this structure:

```
AGENTS.md                          ← Agent instructions (entry point)
router.md                          ← "Domain router" with routing logic
index.yaml                         ← Skill index with dependency graph
spec/ai-ready-data.md              ← Execution model spec
spec/controlled-vocabulary.md      ← Canonical term definitions
spec/requirements-roadmap.yaml     ← 54 requirements across 6 "factors"
spec/plans/IMPLEMENTATION_PLAN.md  ← Implementation tracking
reference/gotchas.md               ← Snowflake pitfalls
reference/placeholders.yaml        ← Template variable catalog
playbooks/assess-rag-readiness/    ← Assessment workflow
playbooks/remediate-rag/           ← Remediation workflow
primitives/{13 dirs}/              ← Each with skill.md + sql/*.sql
```

**Primitives (13):** data-completeness, data-validity, data-consistency, semantic-documentation, business-metadata, access-optimization, embedding-readiness, serving-readiness, change-detection, temporal-integrity, data-provenance, classification, field-masking

Each primitive contains a `skill.md` (reference doc with SQL syntax, parameters, constraints, examples, anti-patterns) and a `sql/` directory with `check-*.sql`, `diagnostic-*.sql`, and `apply-*.sql` files.

---

## Problems

### 1. The layered routing model is over-engineered

The architecture has **four** document types (meta-router, router, playbook, primitive) with **three** routing modes (playbook, guided, reference), event types, thread lifecycle states, and a controlled vocabulary spec. This was designed for a "pluggable skill library" where a parent meta-router delegates to this domain router.

In practice: a user says "assess my data for RAG" and the agent needs to run SQL checks and fix what fails. The routing indirection adds complexity without adding value — the agent can figure out intent without a formal routing spec.

### 2. Massive duplication between skill.md and sql/ files

Every primitive has its SQL inlined in `skill.md` AND also stored as separate `.sql` files. The `skill.md` files are 200-400 lines each, mostly repeating what the SQL files already contain. The playbooks also re-list which primitives map to which requirements, duplicating `index.yaml` and `requirements-roadmap.yaml`.

### 3. The "primitives" abstraction conflates two things

Each "primitive" bundles together: (a) requirement definitions with thresholds, (b) SQL checks, (c) SQL diagnostics, (d) SQL remediations, (e) parameter docs, and (f) Snowflake gotchas. These are mixed into a single `skill.md` that's part reference doc, part test definition, part runbook.

### 4. Not compatible with `npx skills` ecosystem

The `npx skills` CLI expects skills in `skills/<name>/SKILL.md` format with YAML frontmatter (`name`, `description`). This repo has `primitives/<name>/skill.md` (lowercase) with non-standard frontmatter fields (`type`, `domain`, `delegates_to`). The playbooks, router, and spec files have no mapping to the skills format at all.

### 5. The spec/ and reference/ overhead

`controlled-vocabulary.md`, `placeholders.yaml`, `requirements-roadmap.yaml`, and `ai-ready-data.md` are all governance documents that largely restate what's already in the primitives and playbooks. They were designed for a multi-team environment but add maintenance burden for what's effectively a single-concern package.

---

## Proposed Architecture: "Requirements as Tests"

```
skills/
  ai-ready-data/
    SKILL.md                          ← Single entry point (npx skills compatible)

    requirements/                     ← The core: each requirement = one test
      data_completeness.yaml          ← Metadata + thresholds per use-case
      uniqueness.yaml
      schema_conformity.yaml
      ...                             ← One file per requirement (54 total)

    sql/                              ← All SQL in one flat directory
      check/                          ← Assessment queries (read-only)
        data_completeness.sql
        uniqueness.sql
        ...
      diagnostic/                     ← Detail queries (read-only)
        data_completeness.sql
        uniqueness.sql
        ...
      fix/                            ← Remediation queries (mutating)
        fill_nulls.sql
        deduplicate.sql
        enable_change_tracking.sql
        add_clustering_key.sql
        create_masking_policy.sql
        ...

    profiles/                         ← Use-case profiles (what was "playbooks")
      rag.yaml                        ← Which requirements + thresholds for RAG
      ml_training.yaml                ← Which requirements + thresholds for ML
      analytics.yaml                  ← Which requirements + thresholds for analytics

    reference/
      gotchas.md                      ← Snowflake pitfalls (keep this, it's useful)
```

---

## What Each Piece Does

### `SKILL.md`

The single entry point. Contains: what this skill does, how to run an assessment, how to remediate, the execution model (check -> report -> approve -> fix -> verify), Snowflake gotchas inlined or referenced, and delegation rules for masking/classification/semantic views.

Replaces: `AGENTS.md`, `router.md`, `spec/ai-ready-data.md`, and the playbook `.md` files.

### `requirements/*.yaml`

Each requirement is a self-contained test definition:

```yaml
name: data_completeness
description: Fraction of null values across scoped fields
factor: clean
direction: lte                         # lower is better
check: sql/check/data_completeness.sql
diagnostic: sql/diagnostic/data_completeness.sql
fixes:
  - sql/fix/fill_nulls.sql
  - sql/fix/delete_incomplete.sql
  - sql/fix/add_not_null.sql
scope: column                          # schema | table | column
placeholders: [container, namespace, asset, field]
constraints:
  - "NOT NULL constraint will fail if NULLs still exist — fill or delete first"
  - "For tables >1M rows, use sampling"
```

### `profiles/*.yaml`

A profile is a list of requirements with thresholds, grouped into stages:

```yaml
name: rag
description: RAG service readiness
stages:
  - name: Data Quality
    why: Dirty data means garbage retrieval results
    requirements:
      data_completeness: { max: 0.01 }
      uniqueness: { max: 0.01 }
      schema_conformity: { max: 0.001 }
      encoding_validity: { max: 0.0 }
  - name: Schema Understanding
    why: Semantic models enable Text-to-SQL
    requirements:
      semantic_documentation: { min: 0.80 }
      relationship_declaration: { min: 1.00 }
  # ... etc
```

### `sql/`

Flat directories of SQL files. No duplication. Each file is referenced by exactly one requirement YAML.

---

## Migration: What Happens to Each File

| Current File | Fate | Reason |
|---|---|---|
| `AGENTS.md` | Replaced by `SKILL.md` | Single entry point |
| `README.md` | Stays (simplified) | Human docs |
| `router.md` | Deleted | Routing logic moves into `SKILL.md` as simple prose |
| `index.yaml` | Deleted | Replaced by requirement YAML files + profile YAML files |
| `spec/controlled-vocabulary.md` | Deleted | Terms are self-evident from the YAML |
| `spec/ai-ready-data.md` | Merged into `SKILL.md` | Execution model is part of the skill instructions |
| `spec/requirements-roadmap.yaml` | Replaced by `requirements/*.yaml` | Each requirement is now its own file |
| `spec/plans/IMPLEMENTATION_PLAN.md` | Deleted | Implementation tracking doc, not runtime |
| `reference/gotchas.md` | Moved to `skills/ai-ready-data/reference/gotchas.md` | Still useful, keep it |
| `reference/placeholders.yaml` | Deleted | Placeholders declared per-requirement in YAML |
| `primitives/*/skill.md` (13 files) | Deleted | Content split into requirement YAML + SKILL.md |
| `primitives/*/sql/*.sql` (~90 files) | Moved to `sql/check/`, `sql/diagnostic/`, `sql/fix/` | Same content, flat structure |
| `playbooks/assess-rag-readiness/playbook.md` | Replaced by `profiles/rag.yaml` + `SKILL.md` | Workflow logic in SKILL.md, thresholds in profiles |
| `playbooks/remediate-rag/playbook.md` | Replaced by `profiles/rag.yaml` + `SKILL.md` | Same — remediation is just "run fixes for failing checks" |

---

## Why This Is Better

1. **`npx skills` compatible out of the box.** `skills/ai-ready-data/SKILL.md` is the standard format. Install with `npx skills add your-org/ai-ready-data -a cortex`.

2. **One concept per file.** A requirement is a YAML file. A profile is a YAML file. SQL is SQL. No more 400-line markdown files that are part reference, part spec, part runbook.

3. **No routing layer.** The SKILL.md tells the agent: "ask the user what they want to assess, load the profile, run the checks, report, offer to fix." That's prose, not a formal routing spec.

4. **Adding a requirement = adding 2-3 files.** One YAML in `requirements/`, one SQL in `sql/check/`, optionally one in `sql/diagnostic/` and one in `sql/fix/`. Then add a line to the relevant profile YAML. No need to touch a skill.md, router, index, or playbook.

5. **Adding a use-case profile = adding 1 file.** Want ML training assessment? Add `profiles/ml_training.yaml` listing which requirements and thresholds apply. No new playbook needed.

6. **Machine-readable requirement definitions.** The YAML files can be parsed programmatically — you could build a dashboard, generate docs, or validate coverage automatically. The current architecture stores requirements as prose in markdown tables.

7. **~60% fewer files.** From ~100 files to ~40 (54 requirement YAMLs collapse into the sql/ + requirements/ structure, 13 skill.md files disappear, all spec files disappear).

---

## What Stays the Same

- All SQL files are preserved as-is (they're the real value)
- The `reference/gotchas.md` content stays (critical Snowflake knowledge)
- The delegation model to bundled skills (data-policy, sensitive-data-classification, semantic-view-optimization) stays
- The check/diagnostic/fix naming convention stays
- The `{{ placeholder }}` syntax stays
- The 0-1 value convention stays

---

## Implementation Steps

1. Create `skills/ai-ready-data/` directory structure
2. Write `SKILL.md` consolidating router, spec, and playbook workflow logic
3. Create requirement YAML files from `requirements-roadmap.yaml` + primitive `skill.md` metadata
4. Move SQL files from `primitives/*/sql/` into flat `sql/check/`, `sql/diagnostic/`, `sql/fix/` dirs
5. Create `profiles/rag.yaml` from `playbooks/assess-rag-readiness/playbook.md` thresholds
6. Move `reference/gotchas.md` into new structure
7. Update `README.md` to reflect new structure
8. Remove old files (primitives/, playbooks/, router.md, index.yaml, spec/)
9. Verify `npx skills add . -a cortex --list` discovers the skill correctly
