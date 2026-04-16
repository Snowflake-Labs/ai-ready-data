# Check: agent_attribution

Fraction of recent write queries (INSERT, UPDATE, DELETE, MERGE, COPY, CTAS) against the schema that carry a non-empty `QUERY_TAG`.

## Context

Measures whether data-modifying operations in `{{ database }}.{{ schema }}` are attributed via `QUERY_TAG`, the standard Snowflake mechanism for annotating pipeline runs with context (pipeline name, run id, agent identifier, etc.). `user_name` is always populated and is therefore not a meaningful attribution signal.

Uses a 7-day lookback window, ordered by `start_time DESC` and capped at 100,000 rows to bound cost — the `ORDER BY` makes repeated runs deterministic.

`account_usage.query_history` has approximately 45-minute latency — very recent queries may not appear yet. Requires `IMPORTED PRIVILEGES` on the `SNOWFLAKE` database.

Attribution uses `query_history.database_name` / `schema_name` (session schema), not per-object attribution. Cross-schema writes from a session anchored in another schema will not be counted here — for per-target attribution, join against `access_history.objects_modified`.

Returns NULL (N/A) when no write queries occurred in the window.

## SQL

```sql
WITH write_queries AS (
    SELECT
        query_id,
        query_tag
    FROM snowflake.account_usage.query_history
    WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND query_type IN ('INSERT','UPDATE','DELETE','MERGE','COPY','CREATE_TABLE_AS_SELECT')
        AND UPPER(database_name) = UPPER('{{ database }}')
        AND UPPER(schema_name)   = UPPER('{{ schema }}')
    ORDER BY start_time DESC
    LIMIT 100000
)
SELECT
    COUNT_IF(query_tag IS NOT NULL AND query_tag <> '') AS queries_with_attribution,
    COUNT(*) AS total_write_queries,
    COUNT_IF(query_tag IS NOT NULL AND query_tag <> '')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM write_queries
```
