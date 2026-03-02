WITH recent_loads AS (
    SELECT
        COUNT(*) AS total_loads,
        COUNT_IF(
            rows_loaded > 0
            AND DATEDIFF('second', last_load_time, DATEADD('second', rows_loaded / NULLIF(rows_parsed, 0), last_load_time)) IS NOT NULL
        ) AS successful_loads
    FROM {{ container }}.information_schema.load_history
    WHERE schema_name = '{{ namespace }}'
        AND last_load_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
)
SELECT
    successful_loads,
    total_loads,
    successful_loads::FLOAT / NULLIF(total_loads::FLOAT, 0) AS value
FROM recent_loads
