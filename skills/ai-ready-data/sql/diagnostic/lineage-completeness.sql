-- diagnostic-lineage-completeness.sql
-- Shows lineage information from ACCESS_HISTORY for tables
-- Returns: tables with their upstream sources

SELECT
    direct_objects_accessed[0]:objectName::STRING AS target_object,
    direct_objects_accessed[0]:objectDomain::STRING AS target_type,
    base_objects_accessed[0]:objectName::STRING AS source_object,
    base_objects_accessed[0]:objectDomain::STRING AS source_type,
    user_name AS modified_by,
    query_start_time,
    ARRAY_SIZE(base_objects_accessed) AS source_count,
    CASE
        WHEN ARRAY_SIZE(base_objects_accessed) > 0 THEN 'HAS_LINEAGE'
        ELSE 'NO_LINEAGE'
    END AS lineage_status
FROM snowflake.account_usage.access_history
WHERE query_start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    AND ARRAY_SIZE(direct_objects_accessed) > 0
    AND (
        direct_objects_accessed[0]:objectName::STRING LIKE '{{ database }}.{{ schema }}.%'
        OR base_objects_accessed[0]:objectName::STRING LIKE '{{ database }}.{{ schema }}.%'
    )
ORDER BY query_start_time DESC
LIMIT 100
