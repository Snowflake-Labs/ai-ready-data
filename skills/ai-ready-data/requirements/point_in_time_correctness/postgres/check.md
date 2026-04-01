# Check: point_in_time_correctness

Fraction of feature tables that support point-in-time joins preventing future data leakage.

## Context

Scans `information_schema.columns` for timestamp-family columns (`timestamp without time zone`, `timestamp with time zone`, `date`) whose names follow common event-time patterns (`%event%`, `%created%`, `%timestamp%`, `%_at`, `%_date`, `%_time`, `%valid_from%`, `%valid_to%`). A table that contains at least one such column is counted as capable of point-in-time joins.

This heuristic is the same approach used on Snowflake — temporal column presence is the proxy signal. PostgreSQL uses different type names (`timestamp without time zone` vs Snowflake's `TIMESTAMP_NTZ`) but the pattern is identical.

A score of 1.0 means every base table in the schema has a recognizable event-timestamp column. Tables without one may still have temporal data under non-standard names.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_event_timestamp AS (
    SELECT DISTINCT c.table_name
    FROM information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type IN (
            'timestamp without time zone',
            'timestamp with time zone',
            'date'
        )
        AND (
            LOWER(c.column_name) LIKE '%event%'
            OR LOWER(c.column_name) LIKE '%created%'
            OR LOWER(c.column_name) LIKE '%timestamp%'
            OR LOWER(c.column_name) LIKE '%_at'
            OR LOWER(c.column_name) LIKE '%_date'
            OR LOWER(c.column_name) LIKE '%_time'
            OR LOWER(c.column_name) LIKE '%valid_from%'
            OR LOWER(c.column_name) LIKE '%valid_to%'
        )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_event_timestamp) AS tables_with_timestamps,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_event_timestamp)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
```
