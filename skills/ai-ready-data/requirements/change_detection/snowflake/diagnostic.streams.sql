SHOW STREAMS IN SCHEMA {{ database }}.{{ schema }};

SELECT
    "name" AS stream_name,
    "source_name" AS table_name,
    "type" AS stream_type,
    "stale",
    "stale_after"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY "source_name", "name"
