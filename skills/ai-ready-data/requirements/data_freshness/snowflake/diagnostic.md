# Diagnostic: data_freshness

Per-table breakdown of data freshness showing staleness in hours.

## Context

Lists every base table in the schema ordered by `last_altered` ascending (stalest first), along with row count and hours since the last alteration. Use this to identify which specific tables are stale and by how much.

`last_altered` reflects DDL changes, not DML — tables that only receive inserts/updates/deletes will not show an updated timestamp here. For true freshness, prefer streams, dynamic table `DATA_TIMESTAMP`, or explicit timestamp columns.

## SQL

```sql
SELECT
    table_name,
    table_type,
    row_count,
    last_altered,
    DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) AS hours_since_update
FROM {{ database }}.information_schema.tables
WHERE table_schema = '{{ schema }}'
    AND table_type = 'BASE TABLE'
ORDER BY last_altered ASC
```