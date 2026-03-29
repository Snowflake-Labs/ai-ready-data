-- diagnostic-lineage-completeness.sql
-- Shows lineage information from ACCESS_HISTORY for tables
-- Returns: tables with their upstream sources

SELECT
    doa.value:objectName::STRING AS target_object,
    doa.value:objectDomain::STRING AS target_type,
    boa.value:objectName::STRING AS source_object,
    boa.value:objectDomain::STRING AS source_type,
    h.user_name AS modified_by,
    h.query_start_time,
    ARRAY_SIZE(h.base_objects_accessed) AS source_count,
    CASE
        WHEN ARRAY_SIZE(h.base_objects_accessed) > 0 THEN 'HAS_LINEAGE'
        ELSE 'NO_LINEAGE'
    END AS lineage_status
FROM snowflake.account_usage.access_history h,
    LATERAL FLATTEN(input => h.direct_objects_accessed) doa,
    LATERAL FLATTEN(input => h.base_objects_accessed) boa
WHERE h.query_start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
    AND (
        UPPER(SPLIT_PART(doa.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(doa.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
    )
ORDER BY h.query_start_time DESC
LIMIT 100
