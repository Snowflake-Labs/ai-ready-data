-- check-lineage-completeness.sql
-- Checks fraction of tables with documented lineage in ACCESS_HISTORY
-- Returns: value (float 0-1) - fraction of tables with lineage data

-- Note: ACCESS_HISTORY has ~2 hour latency for new objects
WITH tables_in_scope AS (
    SELECT DISTINCT
        table_catalog || '.' || table_schema || '.' || table_name AS full_name
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
tables_with_lineage AS (
    SELECT DISTINCT
        base_objects_accessed[0]:objectName::STRING AS table_name
    FROM snowflake.account_usage.access_history
    WHERE query_start_time >= DATEADD(day, -30, CURRENT_TIMESTAMP())
        AND ARRAY_SIZE(base_objects_accessed) > 0
        AND base_objects_accessed[0]:objectDomain::STRING = 'Table'
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t 
     WHERE EXISTS (SELECT 1 FROM tables_with_lineage l WHERE l.table_name LIKE '%' || SPLIT_PART(t.full_name, '.', 3) || '%')
    ) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    CASE
        WHEN (SELECT COUNT(*) FROM tables_in_scope) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM tables_in_scope t 
              WHERE EXISTS (SELECT 1 FROM tables_with_lineage l WHERE l.table_name LIKE '%' || SPLIT_PART(t.full_name, '.', 3) || '%')
             )::FLOAT / (SELECT COUNT(*) FROM tables_in_scope)::FLOAT
    END AS value
