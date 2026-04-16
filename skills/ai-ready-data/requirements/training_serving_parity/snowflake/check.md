# Check: training_serving_parity

Fraction of feature tables in the schema that are implemented as dynamic tables (shared transformation logic between batch training and low-latency serving paths).

## Context

Heuristic check: feature tables are identified by name pattern (`feature` or `feat_` substring, anchored with `REGEXP_LIKE` so the `_` isn't interpreted as a LIKE wildcard). A feature table implemented as a dynamic table has the same SQL definition driving both training snapshots and incremental serving — so parity is guaranteed by construction. A base-table feature must be rebuilt by a separate serving pipeline, so parity is at risk.

True parity verification requires comparing DDL across the batch and serving paths; this check is only a structural proxy. Returns NULL (N/A) when the schema contains no feature tables.

## SQL

```sql
WITH feature_tables AS (
    SELECT
        table_name,
        table_type
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type IN ('BASE TABLE','DYNAMIC TABLE')
        AND REGEXP_LIKE(LOWER(table_name), '.*(feature|feat_).*')
)
SELECT
    COUNT_IF(table_type = 'DYNAMIC TABLE') AS dynamic_feature_tables,
    COUNT(*) AS total_feature_tables,
    COUNT_IF(table_type = 'DYNAMIC TABLE')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM feature_tables
```
