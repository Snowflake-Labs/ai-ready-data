SELECT
    t.table_name,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM {{ database }}.information_schema.columns c
            WHERE c.table_schema = '{{ schema }}'
                AND c.table_name = t.table_name
                AND LOWER(c.column_name) IN ('version', 'version_id', 'data_version', 'snapshot_id', 'batch_id')
        ) THEN 'HAS_VERSION_COLUMN'
        ELSE 'NO_VERSION_COLUMN'
    END AS version_status,
    COALESCE(
        (SELECT LISTAGG(c.column_name, ', ')
         FROM {{ database }}.information_schema.columns c
         WHERE c.table_schema = '{{ schema }}'
             AND c.table_name = t.table_name
             AND LOWER(c.column_name) IN ('version', 'version_id', 'data_version', 'snapshot_id', 'batch_id')
        ), 'none'
    ) AS version_columns
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY version_status, t.table_name
