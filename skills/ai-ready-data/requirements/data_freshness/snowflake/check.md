# Check: data_freshness

Fraction of base tables whose `last_altered` timestamp is within the configured freshness window.

## Context

Uses `information_schema.tables.last_altered` to compare each base table against `{{ freshness_threshold_hours }}`.

**Important caveat:** `last_altered` reflects DDL changes (and certain metadata operations), not DML row inserts. A table can continuously receive new rows via INSERT/COPY without its `last_altered` moving. For true data freshness, prefer:

- streams (the `last_altered` equivalent for stream metadata is more DML-sensitive),
- dynamic table `data_timestamp`, or
- an explicit timestamp column on the table itself.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
SELECT
    COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }})
        AS fresh_tables,
    COUNT(*) AS total_tables,
    COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }})::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.information_schema.tables
WHERE UPPER(table_schema) = UPPER('{{ schema }}')
    AND table_type = 'BASE TABLE'
```
