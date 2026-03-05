WITH recent_loads AS (
    SELECT
        COUNT(*) AS total_loads,
        COUNT_IF(status = 'LOADED' AND errors_seen = 0) AS successful_loads
    FROM {{ database }}.information_schema.load_history
    WHERE UPPER(schema_name) = UPPER('{{ schema }}')
        AND last_load_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
)
SELECT
    successful_loads,
    total_loads,
    successful_loads::FLOAT / NULLIF(total_loads::FLOAT, 0) AS value
FROM recent_loads
