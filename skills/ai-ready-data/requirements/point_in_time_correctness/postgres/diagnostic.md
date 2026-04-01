# Diagnostic: point_in_time_correctness

Per-table breakdown of temporal columns for point-in-time join capability.

## Context

Lists every base table in the schema with its temporal columns (if any), a count of timestamp columns, and a capability assessment. Tables without timestamp columns are flagged as `NO_TIMESTAMPS` — these cannot support point-in-time joins and risk future data leakage in training pipelines.

PostgreSQL uses `STRING_AGG` instead of Snowflake's `LISTAGG` for column name aggregation.

## SQL

```sql
WITH timestamp_columns AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.is_nullable
    FROM information_schema.columns c
    JOIN information_schema.tables t
        ON c.table_schema = t.table_schema AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN (
            'timestamp without time zone',
            'timestamp with time zone',
            'date'
        )
),
tables_summary AS (
    SELECT
        table_name,
        COUNT(*) AS timestamp_column_count,
        STRING_AGG(column_name, ', ' ORDER BY column_name) AS timestamp_columns
    FROM timestamp_columns
    GROUP BY table_name
)
SELECT
    t.table_name,
    COALESCE(ts.timestamp_column_count, 0) AS timestamp_column_count,
    COALESCE(ts.timestamp_columns, 'NONE') AS timestamp_columns,
    CASE
        WHEN ts.timestamp_column_count > 0 THEN 'HAS_TIMESTAMPS'
        ELSE 'NO_TIMESTAMPS'
    END AS pit_capability,
    CASE
        WHEN ts.timestamp_column_count > 0 THEN 'Can support point-in-time joins'
        ELSE 'Add event timestamp column for temporal queries'
    END AS recommendation
FROM information_schema.tables t
LEFT JOIN tables_summary ts ON t.table_name = ts.table_name
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY pit_capability DESC, t.table_name
```
