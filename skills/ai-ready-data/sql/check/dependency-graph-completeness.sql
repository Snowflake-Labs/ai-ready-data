-- check-dependency-graph-completeness.sql
-- Checks if tables have documented dependencies via OBJECT_DEPENDENCIES
-- Returns: value (float 0-1) - fraction of tables with dependency information

WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('BASE TABLE', 'VIEW', 'DYNAMIC TABLE')
),
tables_with_dependencies AS (
    SELECT DISTINCT referencing_object_name AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE referencing_database = '{{ database }}'
        AND referencing_schema = '{{ schema }}'
    UNION
    SELECT DISTINCT referenced_object_name AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE referenced_database = '{{ database }}'
        AND referenced_schema = '{{ schema }}'
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t 
     WHERE t.table_name IN (SELECT table_name FROM tables_with_dependencies)
    ) AS tables_with_dependencies,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    CASE
        WHEN (SELECT COUNT(*) FROM tables_in_scope) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM tables_in_scope t 
              WHERE t.table_name IN (SELECT table_name FROM tables_with_dependencies)
             )::FLOAT / (SELECT COUNT(*) FROM tables_in_scope)::FLOAT
    END AS value
