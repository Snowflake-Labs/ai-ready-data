SHOW TABLES IN SCHEMA {{ container }}.{{ namespace }};

SELECT
    "name" AS table_name,
    "rows" AS row_count,
    "change_tracking",
    CASE
        WHEN "change_tracking" = 'ON' THEN 'ENABLED'
        ELSE 'NEEDS ENABLING'
    END AS status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
ORDER BY "change_tracking" DESC, "name"
