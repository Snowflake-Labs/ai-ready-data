# Diagnostic: access_audit_coverage

Per-table breakdown of access audit coverage over the last 30 days.

## Context

Shows each base table with its access count, distinct user count, and first/last access timestamps. Tables with status `NO_ACCESS_RECORDED` either have not been queried in the 30-day window or were created within the ~2-hour `access_history` latency window.

Use this to identify which specific tables lack audit trail entries and whether the gap is due to inactivity or a permissions issue.

## SQL

```sql
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
```