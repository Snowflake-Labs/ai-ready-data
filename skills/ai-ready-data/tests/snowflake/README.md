# Snowflake Test Harness — AI-Ready Data Assessment

Validates the AI-ready data assessment check queries against controlled test fixtures with known expected scores.

## Prerequisites

- Snowflake account (Standard edition minimum; Enterprise for full coverage)
- A database where you have `CREATE SCHEMA` privileges
- [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli) (`snow`) or a SQL worksheet
- **Enterprise features (optional):** Search optimization, row access policies, tags
- **For delayed checks:** `GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE <your_role>`

## Files

| File | Purpose |
|---|---|
| `setup.sql` | Creates `AI_READY_TEST` schema with fixtures across all 6 factors |
| `validate.sql` | Runs check queries and outputs requirement / expected / actual / PASS or FAIL |
| `teardown.sql` | Drops the `AI_READY_TEST` schema and all objects |

## Running the Tests

```bash
# 1. Create test schema and fixtures
snow sql -f setup.sql -d YOUR_DATABASE [-c connection]

# 2. Run validation checks
snow sql -f validate.sql -d YOUR_DATABASE [-c connection]

# 3. Clean up
snow sql -f teardown.sql -d YOUR_DATABASE [-c connection]
```

Or as a single pipeline:

```bash
snow sql -f setup.sql -d YOUR_DB && \
snow sql -f validate.sql -d YOUR_DB && \
snow sql -f teardown.sql -d YOUR_DB
```

## Expected Output

Each validation check returns a single-row result:

```
REQUIREMENT                   | EXPECTED | ACTUAL | STATUS
------------------------------+----------+--------+-------
data_completeness (value_col) |     0.90 | 0.9000 | PASS
uniqueness                    |     0.95 | 0.9500 | PASS
search_optimization           |     0.50 | 0.0000 | SKIP (requires Enterprise edition)
row_access_policy             |     0.50 | 0.0000 | SKIP (account_usage latency)
```

A tolerance of `±0.02` is used for PASS/FAIL determination. All immediate checks should return PASS when run against the controlled fixtures.

## Check Categories

### Immediate Checks (20)

These checks run against fixture data or `information_schema` and produce results immediately.

### SHOW + RESULT_SCAN Checks

`search_optimization`, `change_detection`, and `point_lookup_availability` use `SHOW TABLES` with `RESULT_SCAN`. They run in the same session and produce results immediately. `search_optimization` requires Enterprise edition — Standard edition shows SKIP.

### Delayed Checks (3) — `account_usage`

Checks using `snowflake.account_usage` views have ~2 hour propagation delay. They show `SKIP` if run immediately after setup. Wait at least 2 hours, then rerun `validate.sql` for accurate results.

| Requirement | Dependency | Immediate | After 2hr |
|---|---|---|---|
| `row_access_policy` | `policy_references` | SKIP (0.00) | PASS (0.50) |
| `classification` | `tag_references` | SKIP (0.00) | PASS (0.50) |
| `retention_policy` | `tag_references` | SKIP (0.00) | PASS (0.50) |

These also require Enterprise edition for the tags/policies to be created during setup.

## Snowflake vs PostgreSQL Differences

| Aspect | PostgreSQL | Snowflake |
|---|---|---|
| Row generation | `generate_series()` | `TABLE(GENERATOR(ROWCOUNT => N))` |
| JSON validation | Custom `is_valid_json()` function | Built-in `TRY_PARSE_JSON()` |
| Index optimization | B-tree / GIN indexes | Clustering keys / search optimization |
| Change tracking | Trigger-based CDC | Native `CHANGE_TRACKING` |
| Row-level security | `ENABLE ROW LEVEL SECURITY` + policies | Row access policies (Enterprise) |
| Classification | `pg_seclabel` / comments | Tags via `CREATE TAG` (Enterprise) |
| Freshness signal | `pg_stat_user_tables.last_analyze` | `information_schema.tables.last_altered` |
| Metadata checks | `pg_class`, `pg_namespace`, etc. | `information_schema` + `SHOW` commands |
| Data staleness test | `ANALYZE` on one table, skip the other | Cannot simulate — both tables are fresh |
| Constraint enforcement | PK/UNIQUE enforced | PK/UNIQUE are metadata-only |

## Enterprise Edition Features

Some fixtures require Enterprise edition. Setup uses exception handlers to skip these gracefully on Standard edition:

| Feature | Fixture | Validation impact |
|---|---|---|
| Search optimization | `test_search_opt` | Shows SKIP on Standard |
| Row access policies | `test_rap_enabled` | Shows SKIP without Enterprise + latency |
| Tags (classification) | `test_classified` | Shows SKIP without Enterprise + latency |
| Tags (retention) | `test_with_retention` | Shows SKIP without Enterprise + latency |

## Fixture Design

Fixtures are organized by the six AI-readiness factors:

| Factor | Fixture tables | Key checks |
|---|---|---|
| **Clean** | `test_completeness`, `test_uniqueness`, `test_encoding`, `test_syntactic`, `test_range`, `test_categorical`, `test_ref_integrity_*`, `test_cross_column` | data_completeness, uniqueness, encoding_validity, syntactic_validity, value_range_validity, categorical_validity, referential_integrity, cross_column_consistency |
| **Contextual** | `test_documented`, `test_undocumented`, `test_constrained`, `test_unconstrained`, `test_with_pk`, `test_no_pk` | semantic_documentation, constraint_declaration, entity_identifier_declaration |
| **Consumable** | `test_clustered`, `test_no_cluster`, `test_search_opt`, `test_no_search`, `test_with_cluster_lookup`, `test_heap_only` | access_optimization, search_optimization, point_lookup_availability |
| **Current** | `test_fresh_data`, `test_stale_data`, `test_temporal_refs`, `test_cdc_tracked`, `test_no_cdc` | data_freshness, temporal_referential_integrity, change_detection |
| **Correlated** | `test_with_provenance`, `test_no_provenance`, `test_traceable`, `test_no_trace` | data_provenance, record_level_traceability |
| **Compliant** | `test_rap_enabled`, `test_rap_disabled`, `test_classified`, `test_unclassified`, `test_with_retention`, `test_no_retention` | row_access_policy, classification, retention_policy |

## Adding New Checks

To validate a new requirement:

1. Add fixture tables to `setup.sql` with known data distributions
2. Add a validation block to `validate.sql` following the pattern:

```sql
WITH check_result AS (
    -- Inline the check SQL from requirements/{name}/snowflake/check.md
    -- Replace {{ database }}.{{ schema }} with AI_READY_TEST
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
