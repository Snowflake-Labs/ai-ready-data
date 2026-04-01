# PostgreSQL Test Harness — AI-Ready Data Assessment

Validates the AI-ready data assessment check queries against controlled test fixtures with known expected scores.

## Prerequisites

- PostgreSQL 15+ (required for `SECURITY LABEL`, `gen_random_uuid()`, and RLS features)
- A database where you have `CREATE SCHEMA` privileges
- **Optional:** [pgvector](https://github.com/pgvector/pgvector) extension for embedding-related checks

## Files

| File | Purpose |
|---|---|
| `setup.sql` | Creates `ai_ready_test` schema with fixtures across all 6 factors |
| `validate.sql` | Runs check queries and outputs requirement / expected / actual / PASS or FAIL |
| `teardown.sql` | Drops the `ai_ready_test` schema and all objects |

## Running the Tests

```bash
# 1. Create test schema and fixtures
psql -d your_database -f setup.sql

# 2. Run validation checks
psql -d your_database -f validate.sql

# 3. Clean up
psql -d your_database -f teardown.sql
```

Or as a single pipeline:

```bash
psql -d your_database -f setup.sql && \
psql -d your_database -f validate.sql && \
psql -d your_database -f teardown.sql
```

## Expected Output

Each validation check prints a single-row result:

```
     requirement      | expected | actual | status
----------------------+----------+--------+--------
 data_completeness    |     0.90 | 0.9000 | PASS
 uniqueness           |     0.95 | 0.9500 | PASS
 row_access_policy    |     0.50 | 0.5000 | PASS
```

A tolerance of `±0.02` is used for PASS/FAIL determination. All checks should return PASS when run against the controlled fixtures.

## Fixture Design

Fixtures are organized by the six AI-readiness factors:

| Factor | Fixture tables | Key checks |
|---|---|---|
| **Clean** | `test_completeness`, `test_uniqueness`, `test_encoding`, `test_syntactic`, `test_range`, `test_categorical`, `test_ref_integrity_*`, `test_cross_column`, `test_outliers`, `test_distribution` | data_completeness, uniqueness, encoding_validity, syntactic_validity, value_range_validity, categorical_validity, referential_integrity, cross_column_consistency |
| **Contextual** | `test_documented`, `test_undocumented`, `test_constrained`, `test_unconstrained`, `test_with_pk`, `test_no_pk`, `test_with_fk`, `test_no_fk`, `test_temporal`, `test_no_temporal`, `test_with_units`, `test_no_units` | semantic_documentation, constraint_declaration, entity_identifier_declaration, relationship_declaration, temporal_scope_declaration, unit_of_measure_declaration |
| **Consumable** | `test_indexed`, `test_no_index`, `test_gin_search`, `test_no_search`, `test_with_pk_lookup`, `test_heap_only`, `test_embeddings`, `test_no_embeddings`, `test_jsonb_native`, `test_text_json`, `test_chunked`, `test_not_chunked`, `test_eval_data`, `test_customers_eval` | access_optimization, search_optimization, point_lookup_availability, embedding_coverage, native_format_availability, chunk_readiness, eval_coverage |
| **Current** | `test_fresh_data`, `test_stale_data`, `test_temporal_refs`, `test_cdc_tracked`, `test_no_cdc`, `test_pit_correct` | data_freshness, temporal_referential_integrity, change_detection, point_in_time_correctness |
| **Correlated** | `test_with_provenance`, `test_no_provenance`, `v_test_lineage`, `test_traceable`, `test_no_trace`, `test_agent_attributed`, `test_transform_documented`, `test_pipeline_audit`, `mv_test_dependency` | data_provenance, lineage_completeness, record_level_traceability, agent_attribution, transformation_documentation, pipeline_execution_audit, dependency_graph_completeness |
| **Compliant** | `test_rls_enabled`, `test_rls_disabled`, `test_pii_masked`, `test_pii_exposed`, `test_classified`, `test_unclassified`, `test_with_retention`, `test_no_retention`, `test_with_consent`, `test_access_audit_log` | row_access_policy, classification, retention_policy, column_masking, consent_coverage, access_audit_coverage |

## pgvector-Dependent Tests

The `test_embeddings` table is created conditionally:

- **With pgvector:** Includes a `vector(384)` column with random embeddings. Embedding coverage and vector index checks will produce meaningful scores.
- **Without pgvector:** Created as a plain table without the vector column. Embedding-related checks will reflect the gap (score = 0 for those requirements).

The setup script handles this gracefully with a `DO $$ ... EXCEPTION` block — no manual intervention needed.

## Adding New Checks

To validate a new requirement:

1. Add fixture tables to `setup.sql` with known data distributions
2. Add a validation block to `validate.sql` following the pattern:

```sql
WITH check_result AS (
    -- Inline the check SQL from requirements/{name}/postgres/check.md
    -- Replace {{ schema }} with 'ai_ready_test'
    -- Replace {{ asset }} with the fixture table name
    SELECT ... AS value
)
SELECT
    'requirement_name' AS requirement,
    0.XX AS expected,
    ROUND(value, 4) AS actual,
    CASE WHEN ABS(value - 0.XX) < 0.02 THEN 'PASS' ELSE 'FAIL' END AS status
FROM check_result;
```
