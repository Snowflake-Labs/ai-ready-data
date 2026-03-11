# Multi-Platform Extensibility Plan (Option 1 First)

This document is the working plan for refactoring the AI-Ready Data skillset framework to support additional platforms (Databricks, AWS, Azure) while preserving Snowflake behavior.

## Goals

- Make requirement implementation extensible by platform without changing core requirement intent.
- Keep maintainers productive by enforcing clear contracts and predictable contribution flow.
- Preserve existing Snowflake functionality during migration (parity first).
- Prepare interfaces so we can later adopt a declarative IR (Option 2) without major rework.

## Non-Goals (This Refactor)

- No immediate full rewrite to declarative IR.
- No requirement semantic changes unless necessary for portability.
- No breakage of existing assessment/remediation UX.

## Guiding Principles

- Separate requirement intent from execution implementation.
- Standardize contracts before moving files.
- Use explicit capabilities and `N/A` semantics for unsupported features.
- Prefer additive and reversible changes over large-bang migrations.
- Keep one source of truth for skill instructions and contracts.

---

## Target Architecture (Option 1)

### 1) Canonical Requirement Metadata + Platform Implementations

Each requirement keeps one canonical metadata file and one or more platform-specific implementation folders.

Proposed structure:

```text
skills/ai-ready-data/
  requirements/
    {requirement_key}/
      requirement.yaml
      implementations/
        snowflake/
          check.sql
          check.{variant}.sql
          diagnostic.sql
          diagnostic.{variant}.sql
          fix.{name}.sql
        databricks/
          check.sql
          diagnostic.sql
          fix.{name}.sql
        aws/
          check.sql or check.{script/ext}
          diagnostic.sql or diagnostic.{script/ext}
          fix.{name}.sql or fix.{script/ext}
        azure/
          ...
```

Notes:
- `requirement.yaml` remains platform-agnostic and canonical.
- Platform folders are independent and can be implemented incrementally.
- Variant naming convention remains supported.

### 2) Platform Capability Model

Add capability manifests per platform to drive supported vs unsupported behavior.

Proposed location:

```text
skills/ai-ready-data/platforms/
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
```

Examples of capabilities:
- `supports_semantic_views`
- `supports_native_column_masking`
- `supports_lineage_api`
- `supports_vector_index_introspection`
- `supports_account_usage_equivalent`

### 3) Runtime Resolver Contract

Refactor runtime loading so execution resolves by:

1. requirement key
2. platform
3. operation (`check`, `diagnostic`, `fix`)
4. optional variant
5. capabilities

Result semantics:
- `PASS` / `FAIL` when implementation and capabilities exist.
- `N/A` when requirement unsupported for that platform (with reason).

### 4) Output Contract

Normalize output for all platforms:
- `value` (0.0 to 1.0 where applicable)
- `status` (`PASS|FAIL|N/A`)
- `threshold` (when applicable)
- `reason` (required for `N/A`)
- `evidence` (optional structured details)

---

## Skill and Folder Optimizations (Agent Read Efficiency)

### A) Single Source of Truth for Skills

Problem:
- `skills/ai-ready-data/SKILL.md` and `.agents/skills/ai-ready-data/SKILL.md` currently differ.

Plan:
- Choose one canonical source (`skills/...` recommended).
- Auto-sync mirror files via script/check in CI.
- Add CI guard to fail if mirror drift occurs.

### B) Split Large Skill Instructions into Router + Modules

Current:
- `skills/ai-ready-data/SKILL.md` is large and mixes platform-specific and generic logic.

Plan:
- Keep `SKILL.md` as concise router.
- Move deep sections into modular docs:
  - `docs/contracts/execution.md`
  - `docs/workflows/assessment.md`
  - `docs/workflows/remediation.md`
  - `docs/platforms/{platform}/gotchas.md`
  - `docs/platforms/{platform}/permissions.md`

Benefit:
- Better agent context loading.
- Lower risk of stale platform-specific guidance bleeding across platforms.

### C) Add Requirement Index Manifest

Add deterministic discovery file:

```text
skills/ai-ready-data/requirements/index.yaml
```

Purpose:
- Explicit requirement registry for fast, stable loading by agents.
- Optional metadata for factor/workload and platform support.

---

## Contributor Spec Deliverables

## 1) `CONTRIBUTING.md` (repo root)

Must include:
- architecture overview
- platform adapter lifecycle
- requirement contracts
- tests/CI expectations
- PR checklist

## 2) `docs/PLATFORM_CONTRIBUTOR_SPEC.md`

Must include:
- mandatory files for new platform
- capability manifest schema
- implementation quality bar (`check` required, `diagnostic` recommended, `fix` optional)
- `N/A` semantics
- safety/idempotency expectations for fix operations
- conformance test requirements

## 3) Platform README template

Per platform:

```text
docs/platforms/{platform}/README.md
```

With:
- setup/prereqs
- permission model
- known gotchas
- supported requirements matrix

## 4) CI policies

Add checks that:
- validate requirement metadata schema
- validate capability manifest schema
- validate required implementation presence
- enforce skill source/mirror sync

---

## Phased Implementation Plan

### Phase 0 - Contracts and Guardrails

Deliverables:
- execution/result contracts documented
- capability schema documented
- contributor docs scaffolded
- CI guardrails for docs/schema validation

Status: complete (2026-03-11)

Completed artifacts:
- `CONTRIBUTING.md`
- `docs/contracts/execution-contract.md`
- `docs/platforms/capability-schema.md`
- `docs/PLATFORM_CONTRIBUTOR_SPEC.md`
- `skills/ai-ready-data/platforms/{snowflake,databricks,aws,azure}/capabilities.yaml`
- `skills/ai-ready-data/platforms/{snowflake,databricks,aws,azure}/{README.md,gotchas.md}`
- `scripts/validate_phase0.py`
- `.github/workflows/phase0-guardrails.yml`

Validation:
- `python3 scripts/validate_phase0.py` passes locally

Exit criteria:
- team agrees on contracts
- CI enforces schema shape

### Phase 1 - Directory Migration + Resolver Skeleton

Deliverables:
- new `implementations/{platform}` structure for pilot requirements
- resolver logic scaffold using `platform` context
- fallback and `N/A` handling path

Pilot requirements:
- `semantic_documentation`
- `classification`
- `lineage_completeness`

Exit criteria:
- pilot runs end-to-end on Snowflake via new resolver path
- no regression in score semantics for pilot requirements

Status: complete (2026-03-11)

Completed artifacts:
- `scripts/migrate_requirements_layout.py`
- `skills/ai-ready-data/requirements/*/implementations/snowflake/*.sql` (additive copy from legacy SQL)
- `skills/ai-ready-data/requirements/index.yaml` (generated registry)
- `scripts/validate_structure.py` (resolver-ready structure guardrails)
- skill workflow updated to resolve platform implementation path first with legacy fallback (`skills/ai-ready-data/SKILL.md`)

### Phase 2 - Snowflake Parity Migration

Deliverables:
- migrate all Snowflake requirement SQL into `implementations/snowflake`
- maintain existing assessment behavior

Exit criteria:
- full Snowflake assessments pass parity checks
- remediation workflow still functions as expected

Status: complete (2026-03-11)

Completed artifacts:
- all 61 requirements now include Snowflake implementation folders
- legacy root SQL removed; platform implementations are now required
- canonical skill structure/docs updated (`README.md`, `AGENTS.md`, `skills/ai-ready-data/SKILL.md`)
- `.agents` skill mirror synchronized via automation

### Phase 3 - First External Platform Pilot (Databricks preferred)

Deliverables:
- `platforms/databricks/capabilities.yaml`
- implementations for pilot requirements
- platform gotchas/permissions docs

Exit criteria:
- pilot assessment returns valid PASS/FAIL/N/A breakdown
- conformance tests pass for Databricks pilot set

Status: complete (2026-03-11, scaffold level)

Completed artifacts:
- `skills/ai-ready-data/platforms/databricks/capabilities.yaml`
- pilot requirement implementations:
  - `requirements/semantic_documentation/implementations/databricks/{check.sql,diagnostic.sql}`
  - `requirements/classification/implementations/databricks/{check.sql,diagnostic.sql}`
  - `requirements/lineage_completeness/implementations/databricks/{check.sql,diagnostic.sql}`
- Databricks gotchas/README stubs under `skills/ai-ready-data/platforms/databricks/`
- structure validation now enforces pilot Databricks checks exist

### Phase 4 - Full Catalog Expansion and Hardening

Deliverables:
- broaden external platform coverage
- finalize contributor flow and templates
- enforce stricter CI conformance policies

Exit criteria:
- repeatable contributor onboarding for new platform maintainers
- stable multi-platform release process

Status: complete (2026-03-11, foundational hardening)

Completed artifacts:
- contributor onboarding docs:
  - `CONTRIBUTING.md`
  - `docs/PLATFORM_CONTRIBUTOR_SPEC.md`
  - `docs/platforms/capability-schema.md`
- workflow docs:
  - `docs/contracts/execution-contract.md`
  - `docs/workflows/assessment.md`
  - `docs/workflows/remediation.md`
- CI guardrails:
  - `.github/workflows/phase0-guardrails.yml`
  - `scripts/validate_phase0.py`
  - `scripts/validate_structure.py`
- skill mirror automation:
  - `scripts/sync_skill_mirrors.py`

---

## Work Breakdown (Initial Tickets)

1. Define execution and result contract docs.
2. Define capability manifest schema.
3. Add `requirements/index.yaml` registry.
4. Create contributor docs (`CONTRIBUTING.md`, platform spec).
5. Add CI checks for schema and skill sync.
6. Implement runtime resolver with platform dispatch.
7. Migrate pilot requirements to new structure.
8. Add Snowflake parity tests for pilot requirements.
9. Migrate remaining Snowflake requirements.
10. Add Databricks pilot platform pack.

---

## Testing Strategy

### Unit Tests
- resolver path selection
- capability gating
- `N/A` status semantics
- output normalization

### Integration Tests
- assessment stage execution with mixed PASS/FAIL/N/A
- remediation plan generation with platform-specific implementations

### Parity Tests
- old Snowflake path vs new path score parity for selected fixtures

### Conformance Tests (per platform)
- contract compliance for outputs
- required implementation presence
- capability-requirement consistency

---

## Risks and Mitigations

### Risk: Skill instruction drift between mirrored files
- Mitigation: one canonical file + CI drift check + sync script.

### Risk: Migration churn across 61 requirements
- Mitigation: phased migration + parity tests + factor-by-factor rollout.

### Risk: Platform mismatch for governance/introspection features
- Mitigation: explicit capability model + `N/A` semantics, not forced failures.

### Risk: Over-coupling to SQL-only assumptions
- Mitigation: keep operation abstraction generic (`check/diagnostic/fix`) and allow non-SQL backends in adapters.

---

## Definition of Done (Refactor Milestone)

- Platform-aware resolver implemented and used in assessment/remediation.
- Snowflake migrated to platform implementation folders with parity.
- Contributor specification docs added and actionable.
- Skill structure optimized for agent readability and single-source governance.
- CI enforces schema, sync, and conformance checks.
- At least one non-Snowflake platform pilot runs for pilot requirements.

---

## Future Bridge to Option 2 (Declarative IR)

This refactor intentionally prepares for IR by:
- establishing stable execution contracts
- isolating platform logic into adapters
- introducing capability and conformance semantics

When ready, requirement intent can be lifted into IR incrementally without changing top-level assessment UX.
