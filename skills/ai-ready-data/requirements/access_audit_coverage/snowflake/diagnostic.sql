WITH access_log AS (
    SELECT
        f.value:objectName::STRING AS object_name,
        COUNT(*) AS access_count,
        COUNT(DISTINCT user_name) AS distinct_users,
        MIN(query_start_time) AS first_access,
        MAX(query_start_time) AS last_access
    FROM snowflake.account_usage.access_history,
        LATERAL FLATTEN(input => direct_objects_accessed) f
    WHERE f.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
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
