SELECT
    table_name,
    table_type,
    row_count,
    last_altered,
    DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) AS hours_since_update
FROM {{ database }}.information_schema.tables
WHERE table_schema = '{{ schema }}'
    AND table_type = 'BASE TABLE'
ORDER BY last_altered ASC
