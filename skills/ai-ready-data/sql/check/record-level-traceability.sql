WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
traceable_tables AS (
    SELECT COUNT(DISTINCT c.table_name) AS cnt
    FROM {{ container }}.information_schema.columns c
    JOIN {{ container }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
        AND LOWER(c.column_name) IN (
            'correlation_id', 'trace_id', 'request_id', 'event_id',
            'source_id', 'origin_id', 'record_id', 'lineage_id'
        )
)
SELECT
    traceable_tables.cnt AS tables_with_trace_id,
    table_count.cnt AS total_tables,
    traceable_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, traceable_tables
