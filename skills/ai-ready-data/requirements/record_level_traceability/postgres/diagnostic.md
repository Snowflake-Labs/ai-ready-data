# Diagnostic: record_level_traceability

Fraction of records with a unique correlation identifier enabling trace-back to their originating source record.

## Context

Lists every base table in the schema with any detected trace columns and a TRACEABLE / NOT_TRACEABLE status. Use this to identify which tables lack a trace identifier and plan remediation.

PostgreSQL does not expose `row_count` in `information_schema.tables`. The query uses `pg_stat_user_tables.n_live_tup` as a row-count estimate — run `ANALYZE` on tables for accurate counts.

## SQL

```sql
SELECT
    t.table_name,
    COALESCE(s.n_live_tup, 0) AS estimated_row_count,
    COALESCE(
        (SELECT STRING_AGG(c.column_name, ', ')
         FROM information_schema.columns c
         WHERE c.table_schema = '{{ schema }}'
             AND c.table_name = t.table_name
             AND LOWER(c.column_name) IN (
                 'correlation_id', 'trace_id', 'request_id', 'event_id',
                 'source_id', 'origin_id', 'record_id', 'lineage_id'
             )
        ), 'none'
    ) AS trace_columns,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_schema = '{{ schema }}'
                AND c.table_name = t.table_name
                AND LOWER(c.column_name) IN (
                    'correlation_id', 'trace_id', 'request_id', 'event_id',
                    'source_id', 'origin_id', 'record_id', 'lineage_id'
                )
        ) THEN 'TRACEABLE'
        ELSE 'NOT_TRACEABLE'
    END AS status
FROM information_schema.tables t
LEFT JOIN pg_stat_user_tables s
    ON s.schemaname = t.table_schema AND s.relname = t.table_name
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```
