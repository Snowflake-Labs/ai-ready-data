# Check: access_optimization

Fraction of large base tables in the schema that have a clustering key defined.

## Context

Only tables with more than 10,000 rows are evaluated — small tables don't benefit from clustering and would inflate the score. `row_count` in `information_schema.tables` is a materialized estimate, not a live count; it may lag by several minutes after bulk loads.

A clustering key being *present* does not mean it is *effective*. Use the diagnostic to assess clustering depth on individual tables.

Returns NULL (N/A) when the schema contains no tables above the row threshold.

## SQL

```sql
WITH large_tables AS (
    SELECT
        table_name,
        clustering_key
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND table_type = 'BASE TABLE'
      AND row_count > 10000
)
SELECT
    COUNT_IF(clustering_key IS NOT NULL) AS clustered_tables,
    COUNT(*) AS large_tables,
    COUNT_IF(clustering_key IS NOT NULL)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM large_tables
```
