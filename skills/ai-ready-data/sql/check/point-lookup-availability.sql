-- check-point-lookup-availability.sql
-- Checks fraction of tables with clustering or search optimization for fast lookups
-- Returns: value (float 0-1) - fraction of tables with point lookup capability

-- Note: Requires SHOW TABLES + RESULT_SCAN for clustering key info
WITH tables_in_scope AS (
    SELECT table_name
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
)
SELECT
    0 AS tables_with_clustering,  -- Placeholder: requires SHOW TABLES
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    0.0 AS value
-- For accurate results, run:
-- SHOW TABLES IN SCHEMA {{ container }}.{{ namespace }};
-- Then check "cluster_by" IS NOT NULL OR "search_optimization" = 'ON'
