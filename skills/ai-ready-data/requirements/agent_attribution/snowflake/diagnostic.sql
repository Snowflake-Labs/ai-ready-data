-- diagnostic-agent-attribution.sql
-- Shows recent data modifications with agent attribution details
-- Returns: write operations with user/role/query_tag details

SELECT
    query_id,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    query_tag,
    start_time,
    execution_status,
    rows_produced,
    CASE
        WHEN query_tag IS NOT NULL AND query_tag != '' THEN 'ATTRIBUTED'
        ELSE 'UNATTRIBUTED'
    END AS attribution_status
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE', 'COPY', 'CREATE_TABLE_AS_SELECT')
    AND UPPER(database_name) = UPPER('{{ database }}')
    AND UPPER(schema_name) = UPPER('{{ schema }}')
ORDER BY start_time DESC
LIMIT 100
