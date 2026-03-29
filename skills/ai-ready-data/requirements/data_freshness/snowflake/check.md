# Check: data_freshness

Fraction of data assets with a declared freshness SLA that are within their defined freshness window.

## Context

Uses `information_schema.tables` to compare each base table's `last_altered` timestamp against the configured `freshness_threshold_hours`. A table is "fresh" if it was altered within that window.

`last_altered` reflects DDL changes, not DML — a table can receive new rows without updating this timestamp. For true freshness, prefer streams, dynamic table `DATA_TIMESTAMP`, or explicit timestamp columns.

## SQL

```sql
SELECT
    COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }}) AS fresh_tables,
    COUNT(*) AS total_tables,
    COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }})::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.information_schema.tables
WHERE table_schema = '{{ schema }}'
    AND table_type = 'BASE TABLE'
```