-- check-vector-index-coverage.sql
-- Checks fraction of vector columns with search optimization enabled
-- Returns: value (float 0-1) - fraction of vector columns with indexes

-- Note: Vector search optimization in Snowflake is enabled via:
-- ALTER TABLE ... ALTER COLUMN ... SET SEARCH OPTIMIZATION = ON
-- This check looks for tables with search optimization containing vector columns

WITH vector_tables AS (
    SELECT DISTINCT
        c.table_catalog,
        c.table_schema,
        c.table_name
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type LIKE 'VECTOR%'
),
-- Check search optimization status via SHOW TABLES
-- Note: Requires same-session RESULT_SCAN
tables_in_scope AS (
    SELECT COUNT(*) AS total_vector_tables FROM vector_tables
)
SELECT
    0 AS tables_with_vector_index,  -- Placeholder: requires SHOW TABLES + RESULT_SCAN
    (SELECT total_vector_tables FROM tables_in_scope) AS total_vector_tables,
    0.0 AS value  -- Conservative: assumes no indexes until verified via SHOW TABLES
-- To get accurate results, run:
-- SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};
-- Then query RESULT_SCAN for "search_optimization" = 'ON'
