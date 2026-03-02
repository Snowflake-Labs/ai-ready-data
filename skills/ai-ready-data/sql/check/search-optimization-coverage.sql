SHOW TABLES IN SCHEMA {{ container }}.{{ namespace }};

SELECT
    COUNT_IF("search_optimization" = 'ON') AS optimized_tables,
    COUNT(*) AS total_tables,
    COUNT_IF("search_optimization" = 'ON')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
