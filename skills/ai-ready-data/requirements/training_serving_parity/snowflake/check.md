# Check: training_serving_parity

Fraction of ML features with consistent computation logic between training (batch) and serving (real-time) paths.

## Context

Heuristic check based on dynamic table presence for feature tables; true parity verification requires comparing transformation logic across pipelines.

Counts feature tables (names matching `%feature%` or `%feat_%`) that are dynamic tables versus all feature tables (base + dynamic). A score of 1.0 means every feature table is a dynamic table, suggesting the same transformation logic can serve both training and real-time paths. Static base tables score as training-only, since they lack the automatic refresh pipeline that dynamic tables provide.

## SQL

```sql
WITH dynamic_feature_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'DYNAMIC TABLE'
        AND (
            LOWER(table_name) LIKE '%feature%'
            OR LOWER(table_name) LIKE '%feat_%'
        )
),
all_feature_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('BASE TABLE', 'DYNAMIC TABLE')
        AND (
            LOWER(table_name) LIKE '%feature%'
            OR LOWER(table_name) LIKE '%feat_%'
        )
)
SELECT
    dynamic_feature_tables.cnt AS dynamic_feature_tables,
    all_feature_tables.cnt AS total_feature_tables,
    dynamic_feature_tables.cnt::FLOAT / NULLIF(all_feature_tables.cnt::FLOAT, 0) AS value
FROM dynamic_feature_tables, all_feature_tables
```