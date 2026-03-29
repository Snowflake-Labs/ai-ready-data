# Check: batch_throughput_sufficiency

Fraction of COPY INTO load operations that completed successfully without errors.

## Context

Measures load success rate as a throughput proxy — failed or error-producing loads indicate bottlenecks in the ingestion pipeline. Uses `information_schema.load_history` with a 7-day lookback window.

This is a coarse proxy for true throughput. Limitations:
- `information_schema.load_history` has a 14-day retention limit
- Only covers `COPY INTO` loads — does not capture Snowpipe, `INSERT...SELECT`, or dynamic table refreshes
- True throughput measurement (bytes/sec, compute utilization) requires warehouse-level monitoring via `account_usage.query_history`
- A high success rate does not guarantee sufficient throughput — loads may succeed slowly

If no loads exist in the window, the result is NULL (not applicable).

## SQL

```sql
WITH recent_loads AS (
    SELECT
        COUNT(*) AS total_loads,
        COUNT_IF(status = 'LOADED' AND errors_seen = 0) AS successful_loads
    FROM {{ database }}.information_schema.load_history
    WHERE UPPER(schema_name) = UPPER('{{ schema }}')
        AND last_load_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
)
SELECT
    successful_loads,
    total_loads,
    successful_loads::FLOAT / NULLIF(total_loads::FLOAT, 0) AS value
FROM recent_loads
```
