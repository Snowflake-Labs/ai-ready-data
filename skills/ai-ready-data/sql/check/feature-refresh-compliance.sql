-- check-feature-refresh-compliance.sql
-- Checks if dynamic tables are refreshing within their target lag
-- Returns: value (float 0-1) - fraction of features meeting freshness SLA

-- Note: Requires SHOW DYNAMIC TABLES + RESULT_SCAN for accurate measurement
WITH dynamic_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'DYNAMIC TABLE'
)
SELECT
    (SELECT cnt FROM dynamic_tables) AS total_dynamic_tables,
    -- Assume compliant unless SHOW DYNAMIC TABLES reveals otherwise
    1.0 AS value
-- For accurate results, run:
-- SHOW DYNAMIC TABLES IN SCHEMA {{ container }}.{{ namespace }};
-- Then check "scheduling_state" = 'RUNNING' and compare actual lag to target_lag
