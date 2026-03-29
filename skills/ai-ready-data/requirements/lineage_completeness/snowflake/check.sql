-- check-lineage-completeness.sql
-- Checks fraction of tables with documented lineage in ACCESS_HISTORY
-- Returns: value (float 0-1) - fraction of tables with lineage data

-- Note: ACCESS_HISTORY has ~2 hour latency for new objects.
-- Uses 7-day window (not 30) and caps flattened rows to limit scan cost
-- on large accounts. Diagnostic query retains full 30-day window.
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
access_sample AS (
    SELECT
        obj.value:objectName::STRING AS object_name,
        obj.value:objectDomain::STRING AS object_domain
    FROM snowflake.account_usage.access_history,
        LATERAL FLATTEN(input => base_objects_accessed) obj
    WHERE query_start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND obj.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
    LIMIT 100000
),
tables_with_lineage AS (
    SELECT DISTINCT
        UPPER(SPLIT_PART(object_name, '.', 3)) AS table_name
    FROM access_sample
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t
     WHERE UPPER(t.table_name) IN (SELECT table_name FROM tables_with_lineage)
    ) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_in_scope t
     WHERE UPPER(t.table_name) IN (SELECT table_name FROM tables_with_lineage)
    )::FLOAT / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
