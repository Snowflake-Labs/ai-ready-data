WITH query_stats AS (
    SELECT
        COUNT(*) AS total_queries,
        COUNT_IF(total_elapsed_time <= {{ latency_threshold_ms }}) AS compliant_queries
    FROM snowflake.account_usage.query_history
    WHERE database_name = '{{ container }}'
        AND schema_name = '{{ namespace }}'
        AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND query_type IN ('SELECT')
        AND execution_status = 'SUCCESS'
)
SELECT
    compliant_queries,
    total_queries,
    compliant_queries::FLOAT / NULLIF(total_queries::FLOAT, 0) AS value
FROM query_stats
