SHOW TABLES IN SCHEMA {{ container }}.{{ namespace }};

SELECT
    COUNT_IF("change_tracking" = 'ON') AS tracking_enabled,
    COUNT(*) AS total_tables,
    COUNT_IF("change_tracking" = 'ON')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
