# Diagnostic: lineage_completeness

Per-table lineage detail from `ACCESS_HISTORY` over the last 30 days.

## Context

Shows each target object alongside its upstream source objects, the user who ran the query, and a lineage status flag. Uses `direct_objects_accessed` (targets) cross-joined with `base_objects_accessed` (sources) to surface the full lineage graph.

Tables with `HAS_LINEAGE` have at least one recorded base object; `NO_LINEAGE` indicates no upstream sources were captured. Results are limited to 100 rows and ordered by most recent query first.

Use this to identify which tables lack lineage records and whether the gap is due to inactivity or missing upstream references.

## SQL

```sql
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
```