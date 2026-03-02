SELECT
    COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }}) AS fresh_tables,
    COUNT(*) AS total_tables,
    COUNT_IF(DATEDIFF('hour', last_altered, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }})::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ container }}.information_schema.tables
WHERE table_schema = '{{ namespace }}'
    AND table_type = 'BASE TABLE'
