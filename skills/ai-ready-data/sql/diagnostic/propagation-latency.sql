-- diagnostic-propagation-latency.sql
-- Shows dynamic table lag status vs target
-- Requires SHOW DYNAMIC TABLES followed by RESULT_SCAN

-- Step 1: Run this first
-- SHOW DYNAMIC TABLES IN SCHEMA {{ container }}.{{ namespace }};

-- Step 2: Then query results
SELECT
    "name" AS dynamic_table_name,
    "target_lag" AS target_lag,
    "scheduling_state" AS scheduling_state,
    "last_completed_refresh" AS last_refresh,
    "data_timestamp" AS data_timestamp,
    TIMESTAMPDIFF(
        SECOND, 
        TRY_TO_TIMESTAMP("data_timestamp"), 
        CURRENT_TIMESTAMP()
    ) AS actual_lag_seconds,
    CASE
        WHEN "scheduling_state" = 'RUNNING' THEN 'HEALTHY'
        WHEN "scheduling_state" = 'SUSPENDED' THEN 'SUSPENDED'
        ELSE 'UNKNOWN'
    END AS health_status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY actual_lag_seconds DESC NULLS LAST
