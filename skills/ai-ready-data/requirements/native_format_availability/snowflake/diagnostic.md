# Diagnostic: native_format_availability

Shows each table's format type (native vs external) with size, row count, and a recommendation.

## Context

Joins against `information_schema.tables` and labels each table as NATIVE, EXTERNAL, or OTHER. External tables require runtime format conversion and may benefit from materialization for frequent access patterns.

Placeholders: `database`, `schema`.

## SQL

```sql
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.table_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.table_type = 'EXTERNAL TABLE' THEN 'EXTERNAL'
        WHEN t.table_type IN ('BASE TABLE', 'DYNAMIC TABLE') THEN 'NATIVE'
        ELSE 'OTHER'
    END AS format_type,
    CASE
        WHEN t.table_type = 'EXTERNAL TABLE' THEN 'External data - requires runtime conversion'
        WHEN t.table_type = 'BASE TABLE' THEN 'Native Snowflake format - optimal performance'
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'Native format with auto-refresh'
        ELSE t.table_type
    END AS description,
    CASE
        WHEN t.table_type = 'EXTERNAL TABLE' THEN 'Consider materializing frequently accessed external data'
        ELSE 'Native format - no action needed'
    END AS recommendation
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
ORDER BY format_type DESC, t.row_count DESC
```
