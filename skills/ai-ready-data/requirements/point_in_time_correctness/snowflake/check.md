# Check: point_in_time_correctness

Fraction of base tables in the schema that carry a recognizable event-timestamp column — a prerequisite for point-in-time joins that prevent future-data leakage.

## Context

Scans `information_schema.columns` for timestamp-family columns (`DATE`, `DATETIME`, `TIMESTAMP_LTZ`, `TIMESTAMP_NTZ`, `TIMESTAMP_TZ`) whose names match common event-time patterns (anchored with `REGEXP_LIKE` so literal underscores don't trigger LIKE wildcards). A table counts as point-in-time-capable if it has at least one such column **and** is a base table.

The numerator is intersected with the base-table set, so the score cannot exceed 1.0. Tables with non-standard timestamp column names are not detected — extend the regex or rely on `diagnostic.md` for a manual inventory.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tables_with_event_timestamp AS (
    SELECT DISTINCT UPPER(c.table_name) AS table_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
      ON c.table_catalog = t.table_catalog
     AND c.table_schema = t.table_schema
     AND c.table_name = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('DATE','DATETIME','TIMESTAMP_LTZ','TIMESTAMP_NTZ','TIMESTAMP_TZ')
        AND REGEXP_LIKE(
            LOWER(c.column_name),
            '.*(event|created|timestamp|_at$|_date$|_time$).*'
        )
)
SELECT
    COUNT_IF(t.table_name IN (SELECT table_name FROM tables_with_event_timestamp))
        AS tables_with_timestamps,
    COUNT(*) AS total_tables,
    COUNT_IF(t.table_name IN (SELECT table_name FROM tables_with_event_timestamp))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM tables_in_scope t
```
