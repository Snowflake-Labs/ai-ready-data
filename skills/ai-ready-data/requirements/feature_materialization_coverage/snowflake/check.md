# Check: feature_materialization_coverage

Fraction of table-like objects in the schema that are materialized (dynamic table or materialized view), versus the base-table + materialized total.

## Context

A higher score indicates more of the schema's assets are pre-computed for serving. Base tables that have no materialized counterpart drag the score down. This check does not attempt to determine which base tables should be materialized — use it as a schema-wide indicator, then investigate individual feature tables with the diagnostic.

Returns NULL (N/A) when the schema contains no base tables, dynamic tables, or materialized views.

## SQL

```sql
WITH objects AS (
    SELECT table_type
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND table_type IN ('BASE TABLE','DYNAMIC TABLE','MATERIALIZED VIEW')
)
SELECT
    COUNT_IF(table_type IN ('DYNAMIC TABLE','MATERIALIZED VIEW')) AS materialized_count,
    COUNT(*) AS total_count,
    COUNT_IF(table_type IN ('DYNAMIC TABLE','MATERIALIZED VIEW'))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM objects
```
