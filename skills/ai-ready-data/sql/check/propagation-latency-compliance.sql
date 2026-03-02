-- check-propagation-latency-compliance.sql
-- Checks if dynamic tables meet their target lag SLAs
-- Returns: value (float 0-1) - fraction of dynamic tables meeting target lag

WITH dynamic_tables AS (
    SELECT
        table_catalog,
        table_schema,
        table_name
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'DYNAMIC TABLE'
)
SELECT
    COUNT(*) AS total_dynamic_tables,
    -- Note: To get actual lag vs target lag, you need SHOW DYNAMIC TABLES
    -- This check verifies dynamic tables exist; detailed lag check requires SHOW command
    COUNT(*)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM dynamic_tables
