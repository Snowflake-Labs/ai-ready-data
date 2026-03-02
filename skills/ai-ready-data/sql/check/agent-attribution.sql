-- check-agent-attribution.sql
-- Checks if data modifications have recorded agent information via QUERY_HISTORY
-- Returns: value (float 0-1) - fraction of write queries with user attribution

-- Note: This checks last 7 days of query history
WITH write_queries AS (
    SELECT
        query_id,
        user_name,
        role_name,
        query_type
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE', 'CREATE_TABLE_AS_SELECT')
        AND database_name = '{{ container }}'
        AND schema_name = '{{ namespace }}'
),
queries_with_attribution AS (
    SELECT * FROM write_queries
    WHERE user_name IS NOT NULL AND user_name != ''
)
SELECT
    (SELECT COUNT(*) FROM queries_with_attribution) AS queries_with_attribution,
    (SELECT COUNT(*) FROM write_queries) AS total_write_queries,
    CASE
        WHEN (SELECT COUNT(*) FROM write_queries) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM queries_with_attribution)::FLOAT / 
             (SELECT COUNT(*) FROM write_queries)::FLOAT
    END AS value
