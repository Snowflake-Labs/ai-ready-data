-- check-agent-attribution.sql
-- Checks if data modifications have meaningful attribution via QUERY_TAG
-- Returns: value (float 0-1) - fraction of write queries with a non-empty QUERY_TAG

-- user_name is always populated in Snowflake, so it is not a meaningful
-- attribution signal. QUERY_TAG is the standard mechanism for teams to
-- annotate pipeline runs with context (pipeline name, run id, etc.).
-- Caps scanned rows to limit cost on high-volume accounts.
WITH write_queries AS (
    SELECT
        query_id,
        query_tag
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE', 'COPY', 'CREATE_TABLE_AS_SELECT')
        AND UPPER(database_name) = UPPER('{{ database }}')
        AND UPPER(schema_name) = UPPER('{{ schema }}')
    LIMIT 100000
)
SELECT
    COUNT_IF(query_tag IS NOT NULL AND query_tag != '') AS queries_with_attribution,
    COUNT(*) AS total_write_queries,
    COUNT_IF(query_tag IS NOT NULL AND query_tag != '')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM write_queries
