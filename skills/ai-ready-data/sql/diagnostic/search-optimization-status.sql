SHOW TABLES IN SCHEMA {{ container }}.{{ namespace }};

SELECT
    "name" AS table_name,
    "rows" AS row_count,
    "bytes" AS size_bytes,
    "search_optimization",
    CASE
        WHEN "search_optimization" = 'ON' THEN 'ENABLED'
        ELSE 'NOT ENABLED'
    END AS status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
ORDER BY "search_optimization" DESC, "rows" DESC
