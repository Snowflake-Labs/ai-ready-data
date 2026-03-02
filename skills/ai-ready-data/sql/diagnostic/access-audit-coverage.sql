WITH access_log AS (
    SELECT
        direct_objects_accessed[0]:objectName::STRING AS object_name,
        COUNT(*) AS access_count,
        COUNT(DISTINCT user_name) AS distinct_users,
        MIN(query_start_time) AS first_access,
        MAX(query_start_time) AS last_access
    FROM snowflake.account_usage.access_history
    WHERE direct_objects_accessed[0]:objectDomain::STRING = 'Table'
        AND UPPER(direct_objects_accessed[0]:objectName::STRING) LIKE UPPER('{{ database }}.{{ schema }}.%')
        AND query_start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
    GROUP BY object_name
)
SELECT
    t.table_name,
    COALESCE(a.access_count, 0) AS access_count_30d,
    COALESCE(a.distinct_users, 0) AS distinct_users_30d,
    a.first_access,
    a.last_access,
    CASE WHEN a.object_name IS NOT NULL THEN 'AUDITED' ELSE 'NO_ACCESS_RECORDED' END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN access_log a
    ON UPPER(a.object_name) = UPPER('{{ database }}.{{ schema }}.' || t.table_name)
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
