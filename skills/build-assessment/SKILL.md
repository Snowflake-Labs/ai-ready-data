---
name: build-assessment
description: Build a custom AI-ready data assessment through guided conversation. Interviews the user about their workload, priorities, and thresholds, then generates a curated assessment YAML. Use when the user wants to create, customize, or build an assessment, or says things like "build me an assessment", "create a custom assessment", "none of the built-in assessments fit", or "I need a custom profile".
---

# Build Assessment

Guide the user through creating a custom AI-ready data assessment via structured conversation. The output is a YAML file saved to `skills/ai-ready-data/assessments/`.

## When to Use

- User wants an assessment tailored to a workload not covered by the four built-in assessments (rag, feature-serving, training, agents).
- User wants to combine concerns from multiple assessments.
- User has specific compliance, performance, or quality requirements that differ from the defaults.

## Prerequisites

Read `skills/ai-ready-data/SKILL.md` to understand how assessments work — stages, requirements, thresholds, and overrides.

---

## Workflow

### Phase 1: Understand the Workload

Start with open-ended discovery. The goal is to understand what the user is building so you can recommend the right requirements and thresholds.

Ask:

1. **What are you building?** Get a concrete description — "a RAG pipeline over support tickets", "a feature store for fraud detection", "a fine-tuning dataset for code generation", etc.

2. **What data are you working with?** Structured tables, unstructured documents, semi-structured JSON, embeddings, or a mix. This determines which Consumable requirements are relevant.

3. **Who or what consumes this data?** An LLM, an ML model, an API, a human analyst, an agent. This shapes the Contextual and Consumable stages.

4. **What's your biggest concern?** Data quality, latency, governance, freshness, traceability, or something else. This tells you which factors to weight heavily.

5. **Are there compliance requirements?** PII handling, consent tracking, data retention, licensing constraints. This shapes the Compliant stage.

6. **Is there a base assessment that's close?** If so, use `extends` to derive from it rather than building from scratch.

### Phase 2: Select Requirements Per Factor

Walk through each of the six factors. For each factor, explain what it covers in one sentence, then present the candidate requirements as a curated shortlist based on what you learned in Phase 1.

For each factor, present requirements in this format:

```
── Clean ──
"Dirty data produces wrong answers."

Recommended for your workload:
  ✓ data_completeness     Fraction of null values across columns
  ✓ uniqueness            Fraction of duplicate records
  ✓ encoding_validity     Encoding errors in text columns
  ✓ schema_conformity     Records conforming to declared schema

Also available (not typically needed for your workload):
  ○ distribution_conformity   Statistical distribution checks
  ○ outlier_prevalence        Outlier detection
  ○ referential_accuracy      Ground-truth verification

Include the recommended set, or adjust?
```

Use your understanding from Phase 1 to pre-select. The user should be able to say "looks good" for most factors. Only surface requirements that are plausible for their workload — don't list all 61 every time.

**Decision rules for pre-selection:**

| Signal from Phase 1 | Requirements to include |
|---|---|
| Unstructured documents / text | `chunk_readiness`, `embedding_coverage`, `embedding_dimension_consistency`, `vector_index_coverage`, `retrieval_recall_compliance` |
| Structured tables for ML | `feature_materialization_coverage`, `point_in_time_correctness`, `batch_throughput_sufficiency`, `training_serving_parity` |
| Real-time serving | `serving_latency_compliance`, `point_lookup_availability`, `feature_refresh_compliance`, `propagation_latency_compliance` |
| Agent / Text-to-SQL consumer | Raise `semantic_documentation` and `relationship_declaration` thresholds, add `business_glossary_linkage` |
| PII / regulated data | `classification`, `column_masking`, `row_access_policy`, `consent_coverage`, `anonymization_effectiveness`, `purpose_limitation` |
| Reproducibility matters | `data_version_coverage`, `transformation_documentation`, `dependency_graph_completeness`, `impact_analysis_capability` |
| Freshness SLAs | `change_detection`, `data_freshness`, `propagation_latency_compliance`, `incremental_update_coverage` |

### Phase 3: Set Thresholds

For each selected requirement, propose a default threshold based on the closest built-in assessment. Then ask if the user wants to adjust.

Present thresholds grouped by factor:

```
── Clean ──
  data_completeness       min: 0.99   (99% completeness required)
  uniqueness              min: 0.99   (99% unique records required)
  encoding_validity       min: 1.0    (zero encoding errors)
  schema_conformity       min: 0.999  (99.9% conformity required)

Adjust any thresholds, or looks good?
```

**Threshold guidance to share with the user:**

All scores are 0–1 where 1.0 is perfect. Every threshold is a `min:` — the minimum acceptable score.

- **1.0** = zero tolerance, must be perfect (e.g., encoding errors, syntactic validity)
- **0.999** = near-perfect (e.g., schema conformity — 1 in 1000 violations allowed)
- **0.99** = tight (e.g., completeness, uniqueness — 1 in 100 allowed)
- **0.95** = moderate (e.g., distribution conformity, outlier tolerance)
- **0.80** = strong expectation
- **0.50** = baseline expectation
- **0.30** = aspirational floor (e.g., governance checks that are hard to reach)

### Phase 4: Name and Save

Ask for:

1. **Assessment name** — lowercase, hyphens, descriptive (e.g., `support-ticket-rag`, `fraud-feature-store`)
2. **Description** — one-line summary of the workload and purpose
3. **Extends** (optional) — if derived from a built-in assessment, set `extends` and only emit overrides

Generate the YAML and present it for review before saving.

### Phase 5: Generate and Confirm

Build the assessment YAML. Every assessment has exactly six stages, one per factor:

```yaml
name: {name}
description: {description}
stages:
  - name: Clean
    why: {one-sentence why, tailored to their workload}
    requirements:
      {requirement}: { min: N }
      ...

  - name: Contextual
    why: {why}
    requirements:
      {requirement}: { min: N }
      ...

  - name: Consumable
    why: {why}
    requirements:
      {requirement}: { min: N }
      ...

  - name: Current
    why: {why}
    requirements:
      {requirement}: { min: N }
      ...

  - name: Correlated
    why: {why}
    requirements:
      {requirement}: { min: N }
      ...

  - name: Compliant
    why: {why}
    requirements:
      {requirement}: { min: N }
      ...
```

If using `extends`, generate the override format instead:

```yaml
name: {name}
extends: {base}
description: {description}
overrides:
  skip:
    - {requirement}
  set:
    {requirement}: { min: N }
  add:
    {requirement}: { min: N }
```

**Present the full YAML to the user.** Ask: "Save this to `assessments/{name}.yaml`?"

On confirmation, write the file to `skills/ai-ready-data/assessments/{name}.yaml`.

---

## Conversation Style

- Be concise. Don't explain what each factor is in academic terms — one sentence per factor is enough.
- Pre-select aggressively based on what you learned. The user should approve, not build from scratch.
- Group decisions so the user can say "looks good" to batches, not one requirement at a time.
- If the user says "start from rag" or "base it on training", use `extends` and only walk through the differences.
- Don't ask about requirements that clearly don't apply (e.g., don't ask about `batch_throughput_sufficiency` for a RAG pipeline).

## Reference

The full requirement catalog is in `skills/ai-ready-data/requirements/`. Each YAML file contains `name`, `description`, `factor`, and `workload` fields. Read individual files when you need details about a specific requirement.

The four built-in assessments are in `skills/ai-ready-data/assessments/`:
- `rag.yaml` — 27 requirements
- `feature-serving.yaml` — 39 requirements
- `training.yaml` — 50 requirements
- `agents.yaml` — 37 requirements
