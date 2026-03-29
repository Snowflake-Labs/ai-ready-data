# Diagnostic: retention_policy

Per-table breakdown of retention policy coverage.

## Context

Shows each base table with its row count, Time Travel retention setting, and any retention-related tags. Tables with status `NO_RETENTION_POLICY` have no tag indicating a defined retention or deletion schedule.

`account_usage.tag_references` has approximately 2-hour latency — recently tagged tables may not appear yet. Note: `tag_references` has no `deleted` column — do not filter on it.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    t.retention_time AS time_travel_days,
    tr.tag_name AS retention_tag,
    tr.tag_value AS retention_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_RETENTION_POLICY'
        ELSE 'NO_RETENTION_POLICY'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('retention_days', 'retention_policy', 'data_retention', 'ttl')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```
