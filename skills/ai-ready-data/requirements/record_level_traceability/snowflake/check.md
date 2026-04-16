# Check: record_level_traceability

Fraction of base tables in the schema that contain at least one well-known trace-identifier column.

## Context

Scans `information_schema.columns` for columns whose name (lower-cased) is one of: `correlation_id`, `trace_id`, `request_id`, `event_id`, `source_id`, `origin_id`, `record_id`, `lineage_id`.

A score of 1.0 means every base table has a recognizable trace column. Tables using non-standard naming conventions for their trace identifiers will not be detected — consider standardizing column names or extending the lookup list via a profile override.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
traceable_tables AS (
    SELECT COUNT(DISTINCT c.table_name) AS cnt
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
        AND LOWER(c.column_name) IN (
            'correlation_id','trace_id','request_id','event_id',
            'source_id','origin_id','record_id','lineage_id'
        )
)
SELECT
    traceable_tables.cnt AS tables_with_trace_id,
    table_count.cnt      AS total_tables,
    traceable_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, traceable_tables
```
