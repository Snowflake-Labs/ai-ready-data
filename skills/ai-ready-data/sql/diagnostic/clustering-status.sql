SELECT
    table_name,
    row_count,
    bytes / (1024*1024) AS size_mb,
    clustering_key,
    CASE
        WHEN row_count <= 10000 THEN 'SMALL (OK)'
        WHEN clustering_key IS NOT NULL THEN 'CLUSTERED'
        ELSE 'NEEDS CLUSTERING'
    END AS status
FROM {{ container }}.information_schema.tables
WHERE table_schema = '{{ namespace }}'
    AND table_type = 'BASE TABLE'
ORDER BY row_count DESC
