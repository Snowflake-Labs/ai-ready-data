SELECT
    t.table_name,
    t.table_type,
    t.row_count,
    t.bytes / (1024*1024) AS size_mb,
    CASE
        WHEN t.table_type = 'DYNAMIC TABLE' THEN 'DYNAMIC (serving-ready)'
        WHEN t.table_type = 'BASE TABLE' THEN 'STATIC (training-only)'
        ELSE t.table_type
    END AS parity_status
FROM {{ container }}.information_schema.tables t
WHERE t.table_schema = '{{ namespace }}'
    AND (
        LOWER(t.table_name) LIKE '%feature%'
        OR LOWER(t.table_name) LIKE '%feat_%'
    )
ORDER BY t.table_type, t.table_name
