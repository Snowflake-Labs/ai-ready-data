-- check-lineage-completeness.sql
-- Checks fraction of tables with documented lineage in ACCESS_HISTORY
-- Returns: value (float 0-1) - fraction of tables with lineage data

-- Note: ACCESS_HISTORY has ~2 hour latency for new objects
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_lineage AS (
    SELECT DISTINCT
        SPLIT_PART(obj.value:objectName::STRING, '.', 3) AS table_name
    FROM snowflake.account_usage.access_history,
        LATERAL FLATTEN(input => base_objects_accessed) obj
    WHERE query_start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
        AND obj.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t 
     WHERE UPPER(t.table_name) IN (SELECT UPPER(table_name) FROM tables_with_lineage)
    ) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_in_scope t 
     WHERE UPPER(t.table_name) IN (SELECT UPPER(table_name) FROM tables_with_lineage)
    )::FLOAT / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
