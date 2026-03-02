-- diagnostic-point-lookup-availability.sql
-- Shows tables with clustering and search optimization status
-- Requires SHOW TABLES + RESULT_SCAN

-- Step 1: Run this first
-- SHOW TABLES IN SCHEMA {{ container }}.{{ namespace }};

-- Step 2: Query results
SELECT
    "database_name" AS database_name,
    "schema_name" AS schema_name,
    "name" AS table_name,
    "rows" AS row_count,
    "cluster_by" AS clustering_key,
    "search_optimization" AS search_optimization,
    CASE
        WHEN "cluster_by" IS NOT NULL AND "search_optimization" = 'ON' THEN 'FULLY_OPTIMIZED'
        WHEN "cluster_by" IS NOT NULL THEN 'CLUSTERED_ONLY'
        WHEN "search_optimization" = 'ON' THEN 'SEARCH_OPT_ONLY'
        ELSE 'NOT_OPTIMIZED'
    END AS lookup_capability,
    CASE
        WHEN "cluster_by" IS NOT NULL AND "search_optimization" = 'ON' THEN 'Ready for point lookups'
        WHEN "cluster_by" IS NOT NULL THEN 'Add search optimization for equality predicates'
        WHEN "search_optimization" = 'ON' THEN 'Add clustering for range scans'
        ELSE 'Add clustering key on lookup columns'
    END AS recommendation
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY lookup_capability DESC, "rows" DESC
