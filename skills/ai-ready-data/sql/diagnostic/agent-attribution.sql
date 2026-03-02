-- diagnostic-agent-attribution.sql
-- Shows recent data modifications with agent attribution
-- Returns: write operations with user/role details

SELECT
    query_id,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    start_time,
    execution_status,
    rows_produced,
    CASE
        WHEN user_name IS NOT NULL AND user_name != '' THEN 'ATTRIBUTED'
        ELSE 'UNATTRIBUTED'
    END AS attribution_status
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE', 'CREATE_TABLE_AS_SELECT')
    AND database_name = '{{ database }}'
    AND schema_name = '{{ schema }}'
ORDER BY start_time DESC
LIMIT 100
