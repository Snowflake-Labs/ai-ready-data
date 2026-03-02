SELECT
    table_name,
    last_load_time,
    rows_loaded,
    rows_parsed,
    errors_seen,
    status,
    CASE
        WHEN errors_seen > 0 THEN 'ERRORS'
        WHEN rows_loaded = 0 THEN 'EMPTY_LOAD'
        ELSE 'OK'
    END AS load_status
FROM {{ container }}.information_schema.load_history
WHERE schema_name = '{{ namespace }}'
    AND last_load_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY last_load_time DESC
LIMIT 100
