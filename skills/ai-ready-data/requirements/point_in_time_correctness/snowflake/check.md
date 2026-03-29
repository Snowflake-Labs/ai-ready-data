# Check: point_in_time_correctness

Fraction of feature datasets that support point-in-time joins preventing future data leakage.

## Context

Scans `information_schema.columns` for timestamp-family columns (`DATE`, `DATETIME`, `TIMESTAMP_LTZ`, `TIMESTAMP_NTZ`, `TIMESTAMP_TZ`) whose names follow common event-time patterns (`%event%`, `%created%`, `%timestamp%`, `%_at`, `%_date`, `%_time`). A table that contains at least one such column is counted as capable of point-in-time joins.

A score of 1.0 means every base table in the schema has a recognizable event-timestamp column. Tables without one may still have temporal data under non-standard names — the heuristic is intentionally conservative.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_event_timestamp AS (
    SELECT DISTINCT c.table_name
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ')
        AND (
            LOWER(c.column_name) LIKE '%event%'
            OR LOWER(c.column_name) LIKE '%created%'
            OR LOWER(c.column_name) LIKE '%timestamp%'
            OR LOWER(c.column_name) LIKE '%_at'
            OR LOWER(c.column_name) LIKE '%_date'
            OR LOWER(c.column_name) LIKE '%_time'
        )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_event_timestamp) AS tables_with_timestamps,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_event_timestamp)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```
