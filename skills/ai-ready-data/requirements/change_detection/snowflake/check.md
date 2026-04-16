# Check: change_detection

Fraction of base tables with change tracking enabled.

## Context

Measures whether tables have Snowflake's native change tracking turned on. Change tracking is the foundation for streams, incremental processing, and CDC workflows — without it, downstream consumers must do full-table scans to detect changes.

`change_tracking` status is **not** available in `information_schema.tables` — this check uses `SHOW TABLES` + `RESULT_SCAN`. The two statements must run in the same session; otherwise `RESULT_SCAN` will fail.

### Variant: Stream coverage

An alternative measure of change-detection readiness is stream coverage — whether tables have active (non-stale) streams consuming their changes. This is a stronger signal than change tracking alone because it means the change data is actually being consumed.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

### Change tracking (primary)

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

SELECT
    COUNT_IF("change_tracking" = 'ON') AS tracking_enabled,
    COUNT(*) AS total_tables,
    COUNT_IF("change_tracking" = 'ON')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
```

### Stream coverage (variant)

```sql
SHOW STREAMS IN SCHEMA {{ database }}.{{ schema }};

WITH stream_data AS (
    SELECT UPPER(SPLIT_PART("source_name", '.', -1)) AS table_name
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE "stale" = 'false'
),
table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
streamed_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt FROM stream_data
)
SELECT
    streamed_tables.cnt AS tables_with_streams,
    table_count.cnt     AS total_tables,
    streamed_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, streamed_tables
```
