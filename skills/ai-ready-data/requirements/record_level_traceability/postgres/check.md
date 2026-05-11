# Check: record_level_traceability

Fraction of records with a unique correlation identifier enabling trace-back to their originating source record.

## Context

Scans `information_schema.columns` for well-known trace-identifier column names (`correlation_id`, `trace_id`, `request_id`, `event_id`, `source_id`, `origin_id`, `record_id`, `lineage_id`) across all base tables in the schema. Returns the ratio of tables that contain at least one such column.

A score of 1.0 means every base table has a recognizable trace column. Tables using non-standard naming conventions for their trace identifiers will not be detected — consider standardizing column names or extending the lookup list.

PostgreSQL does not have a `database.schema` namespace — all queries target a single database via `information_schema` directly.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
traceable_tables AS (
    SELECT COUNT(DISTINCT c.table_name) AS cnt
    FROM information_schema.columns c
    JOIN information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND LOWER(c.column_name) IN (
            'correlation_id', 'trace_id', 'request_id', 'event_id',
            'source_id', 'origin_id', 'record_id', 'lineage_id'
        )
)
SELECT
    traceable_tables.cnt AS tables_with_trace_id,
    table_count.cnt AS total_tables,
    traceable_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, traceable_tables
```
