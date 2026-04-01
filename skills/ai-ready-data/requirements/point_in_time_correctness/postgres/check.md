# Check: point_in_time_correctness

Fraction of tables that support point-in-time joins via recognizable temporal columns.

## Context

Scans `information_schema.columns` for timestamp-family columns (`timestamp without time zone`, `timestamp with time zone`, `date`) whose names follow common event-time patterns (`%event%`, `%created%`, `%timestamp%`, `%_at`, `%_date`, `%_time`, `%valid_from%`, `%valid_to%`). A table with at least one such column is counted as capable of point-in-time joins.

This heuristic is identical in spirit to the Snowflake check — both platforms use column naming conventions to infer temporal join capability. PostgreSQL's timestamp types differ from Snowflake's (`TIMESTAMP_LTZ`, `TIMESTAMP_NTZ`, `TIMESTAMP_TZ`) but serve the same purpose.

A score of 1.0 means every base table in the schema has a recognizable event-timestamp column. Tables without one may still have temporal data under non-standard names — the heuristic is intentionally conservative.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT t.table_name
    FROM information_schema.tables t
    WHERE t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
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
