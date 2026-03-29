# Diagnostic: feature_materialization_coverage

Fraction of ML features pre-materialized in both online and offline serving stores.

## Context

Lists every base table, dynamic table, and materialized view in the schema with its materialization status and a recommendation. Ordered so materialized objects appear first, then unmaterialized base tables by row count descending.

## SQL

```sql
-- diagnostic-feature-materialization-coverage.sql
-- Shows tables and their materialization status
-- Returns: tables with materialization details

SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.table_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'DYNAMIC_TABLE'
        WHEN t.table_type = 'MATERIALIZED VIEW' THEN 'MATERIALIZED_VIEW'
        WHEN t.table_type = 'BASE TABLE' THEN 'BASE_TABLE'
        ELSE t.table_type
    END AS materialization_type,
    CASE
        WHEN t.table_type IN ('DYNAMIC TABLE', 'MATERIALIZED VIEW') THEN 'MATERIALIZED'
        ELSE 'NOT_MATERIALIZED'
    END AS materialization_status,
    CASE
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'Auto-refreshing based on target lag'
        WHEN t.table_type = 'MATERIALIZED VIEW' THEN 'Materialized (refresh on base change)'
        ELSE 'Consider dynamic table for pre-computation'
    END AS recommendation
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type IN ('BASE TABLE', 'DYNAMIC TABLE', 'MATERIALIZED VIEW')
ORDER BY materialization_status DESC, t.row_count DESC
```
