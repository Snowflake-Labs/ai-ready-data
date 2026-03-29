# Diagnostic: record_level_traceability

Fraction of records with a unique correlation identifier enabling trace-back to their originating source record.

## Context

Lists every base table in the schema with its row count, any detected trace columns, and a TRACEABLE / NOT_TRACEABLE status. Use this to identify which tables lack a trace identifier and plan remediation.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    COALESCE(
        (SELECT LISTAGG(c.column_name, ', ')
         FROM {{ database }}.information_schema.columns c
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
            SELECT 1 FROM {{ database }}.information_schema.columns c
            WHERE c.table_schema = '{{ schema }}'
                AND c.table_name = t.table_name
                AND LOWER(c.column_name) IN (
                    'correlation_id', 'trace_id', 'request_id', 'event_id',
                    'source_id', 'origin_id', 'record_id', 'lineage_id'
                )
        ) THEN 'TRACEABLE'
        ELSE 'NOT_TRACEABLE'
    END AS status
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```