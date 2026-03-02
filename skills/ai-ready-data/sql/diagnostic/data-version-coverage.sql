SELECT
    t.table_name,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM {{ container }}.information_schema.columns c
            WHERE c.table_schema = '{{ namespace }}'
                AND c.table_name = t.table_name
                AND LOWER(c.column_name) IN ('version', 'version_id', 'data_version', 'snapshot_id', 'batch_id')
        ) THEN 'HAS_VERSION_COLUMN'
        ELSE 'NO_VERSION_COLUMN'
    END AS version_status,
    COALESCE(
        (SELECT LISTAGG(c.column_name, ', ')
         FROM {{ container }}.information_schema.columns c
         WHERE c.table_schema = '{{ namespace }}'
             AND c.table_name = t.table_name
             AND LOWER(c.column_name) IN ('version', 'version_id', 'data_version', 'snapshot_id', 'batch_id')
        ), 'none'
    ) AS version_columns
FROM {{ container }}.information_schema.tables t
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY version_status, t.table_name
