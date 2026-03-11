-- diagnostic-feature-refresh-compliance.sql
-- Shows dynamic table refresh status and lag compliance
-- Requires SHOW DYNAMIC TABLES + RESULT_SCAN

-- Step 1: Run this first
-- SHOW DYNAMIC TABLES IN SCHEMA {{ database }}.{{ schema }};

-- Step 2: Query results
SELECT
    "name" AS dynamic_table_name,
    "target_lag" AS target_lag,
    "scheduling_state" AS scheduling_state,
    "last_completed_refresh" AS last_refresh,
    "data_timestamp" AS data_timestamp,
    "refresh_mode" AS refresh_mode,
    CASE
        WHEN "scheduling_state" = 'RUNNING' THEN 'COMPLIANT'
        WHEN "scheduling_state" = 'SUSPENDED' THEN 'SUSPENDED'
        ELSE 'NON_COMPLIANT'
    END AS compliance_status,
    CASE
        WHEN "scheduling_state" = 'RUNNING' THEN 'Refreshing within target lag'
        WHEN "scheduling_state" = 'SUSPENDED' THEN 'Resume dynamic table for freshness'
        ELSE 'Check dynamic table health'
    END AS recommendation
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY compliance_status DESC, "name"
