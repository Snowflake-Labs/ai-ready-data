SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.search_optimization = 'ON' THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status
FROM {{ database }}.information_schema.columns c
JOIN {{ database }}.information_schema.tables t
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND c.data_type = 'VECTOR'
ORDER BY index_status, t.row_count DESC
