SELECT
    t.table_name,
    t.row_count,
    COALESCE(
        (SELECT LISTAGG(c.column_name, ', ')
         FROM {{ container }}.information_schema.columns c
         WHERE c.table_schema = '{{ namespace }}'
             AND c.table_name = t.table_name
             AND LOWER(c.column_name) IN (
                 'correlation_id', 'trace_id', 'request_id', 'event_id',
                 'source_id', 'origin_id', 'record_id', 'lineage_id'
             )
        ), 'none'
    ) AS trace_columns,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM {{ container }}.information_schema.columns c
            WHERE c.table_schema = '{{ namespace }}'
                AND c.table_name = t.table_name
                AND LOWER(c.column_name) IN (
                    'correlation_id', 'trace_id', 'request_id', 'event_id',
                    'source_id', 'origin_id', 'record_id', 'lineage_id'
                )
        ) THEN 'TRACEABLE'
        ELSE 'NOT_TRACEABLE'
    END AS status
FROM {{ container }}.information_schema.tables t
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
