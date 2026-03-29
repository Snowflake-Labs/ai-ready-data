-- check-access-audit-coverage.sql
-- Checks fraction of tables with access records in ACCESS_HISTORY
-- Returns: value (float 0-1) - fraction of tables with audit data

-- Uses 7-day window (not 30) and caps flattened rows to limit scan cost
-- on large accounts. Diagnostic query retains full 30-day window.
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
access_sample AS (
    SELECT
        f.value:objectName::STRING AS object_name
    FROM snowflake.account_usage.access_history,
        LATERAL FLATTEN(input => direct_objects_accessed) f
    WHERE f.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
        AND query_start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    LIMIT 100000
),
audited_tables AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM access_sample
)
SELECT
    audited_tables.cnt AS tables_with_audit,
    table_count.cnt AS total_tables,
    audited_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, audited_tables
