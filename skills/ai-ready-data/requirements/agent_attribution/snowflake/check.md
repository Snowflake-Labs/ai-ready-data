# Check: agent_attribution

Fraction of data modification queries that have a meaningful attribution identifier via `QUERY_TAG`.

## Context

Measures whether write operations (INSERT, UPDATE, DELETE, MERGE, COPY, CTAS) against the schema are tagged with a `QUERY_TAG` identifying the responsible agent, pipeline, or process. Uses a 7-day lookback window with a 100,000-row cap to limit scan cost on high-volume accounts.

`user_name` is always populated in Snowflake, so it is not a meaningful attribution signal — any query has a user. `QUERY_TAG` is the standard mechanism for teams to annotate pipeline runs with context (pipeline name, run ID, agent identifier, etc.). This check measures `QUERY_TAG` presence specifically.

`account_usage.query_history` has approximately 45-minute latency — very recent queries may not appear. Requires IMPORTED PRIVILEGES on the SNOWFLAKE database.

A score of 1.0 means every write query in the window carried a `QUERY_TAG`. A score of 0.0 means no write queries were tagged. If there are no write queries in the window, the result is NULL (not applicable).

## SQL

```sql
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
```
