# Check: batch_throughput_sufficiency

Fraction of recent `COPY INTO` loads that sustained at least the caller's minimum rows-per-second throughput threshold.

## Context

Uses `snowflake.account_usage.query_history` to evaluate actual throughput of successful `COPY` operations over the last 7 days. Per-query throughput is computed as `rows_produced / (total_elapsed_time / 1000)` (rows/sec). A load counts as "sufficient" when its rows/sec is at or above `{{ min_rows_per_second }}`.

Caveats:

- `query_history` attributes queries by the **session's** current database/schema, not by the tables actually loaded. Cross-schema loads (session in schema A, `COPY INTO B.T`) won't be attributed to B. For strict per-table throughput, join against `access_history`.
- `account_usage` has ~45-minute latency on `query_history` — very recent loads may not appear yet.
- `rows_produced` is a proxy for bytes loaded. If row sizes vary dramatically, consider a bytes-based threshold instead (requires joining `account_usage.copy_history`).
- Zero-rowcount loads are excluded to avoid spurious "instant" throughput.

Returns NULL (N/A) when no successful COPY operations occurred in the window.

## SQL

```sql
WITH copy_queries AS (
    SELECT
        query_id,
        rows_produced,
        total_elapsed_time / 1000.0 AS elapsed_seconds
    FROM snowflake.account_usage.query_history
    WHERE query_type = 'COPY'
      AND UPPER(database_name) = UPPER('{{ database }}')
      AND UPPER(schema_name)   = UPPER('{{ schema }}')
      AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
      AND execution_status = 'SUCCESS'
      AND total_elapsed_time > 0
      AND rows_produced > 0
)
SELECT
    COUNT_IF(rows_produced / NULLIF(elapsed_seconds, 0) >= {{ min_rows_per_second }})
        AS sufficient_loads,
    COUNT(*) AS total_loads,
    COUNT_IF(rows_produced / NULLIF(elapsed_seconds, 0) >= {{ min_rows_per_second }})::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM copy_queries
```
