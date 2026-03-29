SELECT
    table_name,
    last_load_time,
    rows_loaded,
    rows_parsed,
    errors_seen,
    status,
    CASE
        WHEN status = 'LOADED' AND errors_seen = 0 THEN 'OK'
        WHEN errors_seen > 0 THEN 'ERRORS'
        WHEN rows_loaded = 0 THEN 'EMPTY_LOAD'
        ELSE 'OTHER: ' || status
    END AS load_status
FROM {{ database }}.information_schema.load_history
WHERE UPPER(schema_name) = UPPER('{{ schema }}')
    AND last_load_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY last_load_time DESC
LIMIT 100
