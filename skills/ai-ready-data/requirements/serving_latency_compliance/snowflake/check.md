# Check: serving_latency_compliance

Fraction of data serving endpoints meeting their defined latency SLA at p99.

## Context

Queries `snowflake.account_usage.query_history` with a 7-day lookback window, filtering to successful `SELECT` queries in the target schema. Measures SELECT queries only — does not cover API-based serving.

`account_usage.query_history` has approximately 2-hour latency — recently executed queries may not appear yet.

A score of 1.0 means every successful SELECT query completed within the configured `latency_threshold_ms`. Queries that exceed the threshold are counted as non-compliant.

## SQL

```sql
WITH query_stats AS (
    SELECT
        COUNT(*) AS total_queries,
        COUNT_IF(total_elapsed_time <= {{ latency_threshold_ms }}) AS compliant_queries
    FROM snowflake.account_usage.query_history
    WHERE UPPER(database_name) = UPPER('{{ database }}')
        AND UPPER(schema_name) = UPPER('{{ schema }}')
        AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND query_type IN ('SELECT')
        AND execution_status = 'SUCCESS'
)
SELECT
    compliant_queries,
    total_queries,
    compliant_queries::FLOAT / NULLIF(total_queries::FLOAT, 0) AS value
FROM query_stats
```
