# Diagnostic: data_version_coverage

Per-table breakdown of explicit version column presence across the schema.

## Context

Lists every base table and checks whether it contains a recognized version-tracking column (`version`, `version_id`, `data_version`, `snapshot_id`, `batch_id`). Tables are classified as `HAS_VERSION_COLUMN` or `NO_VERSION_COLUMN` and sorted by status.

This is complementary to the check query: the check measures Time Travel `retention_time > 0`, while this diagnostic looks for explicit version columns in the schema. A table may pass the check (Time Travel enabled) but still lack an explicit version column, or vice versa.

Includes row count and size in MB to help prioritize which tables to address first.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM {{ database }}.information_schema.columns c
            WHERE c.table_schema = '{{ schema }}'
                AND c.table_name = t.table_name
                AND LOWER(c.column_name) IN ('version', 'version_id', 'data_version', 'snapshot_id', 'batch_id')
        ) THEN 'HAS_VERSION_COLUMN'
        ELSE 'NO_VERSION_COLUMN'
    END AS version_status,
    COALESCE(
        (SELECT LISTAGG(c.column_name, ', ')
         FROM {{ database }}.information_schema.columns c
         WHERE c.table_schema = '{{ schema }}'
             AND c.table_name = t.table_name
             AND LOWER(c.column_name) IN ('version', 'version_id', 'data_version', 'snapshot_id', 'batch_id')
        ), 'none'
    ) AS version_columns
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY version_status, t.table_name
```