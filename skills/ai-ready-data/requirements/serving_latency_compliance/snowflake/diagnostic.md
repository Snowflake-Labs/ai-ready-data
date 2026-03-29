# Diagnostic: serving_latency_compliance

Per-query breakdown of latency compliance over the last 7 days.

## Context

Returns the slowest 100 successful SELECT queries in the target schema, each labeled as `COMPLIANT` or `EXCEEDS_SLA` against the configured `latency_threshold_ms`. Includes elapsed time, bytes scanned, rows produced, and warehouse name to help identify optimization targets.

Measures SELECT queries only — does not cover API-based serving. `account_usage.query_history` has approximately 2-hour latency.

## SQL

```sql
SELECT
    query_id,
    query_text,
    total_elapsed_time AS elapsed_ms,
    bytes_scanned,
    rows_produced,
    warehouse_name,
    start_time,
    CASE
        WHEN total_elapsed_time <= {{ latency_threshold_ms }} THEN 'COMPLIANT'
        ELSE 'EXCEEDS_SLA'
    END AS status
FROM snowflake.account_usage.query_history
WHERE UPPER(database_name) = UPPER('{{ database }}')
    AND UPPER(schema_name) = UPPER('{{ schema }}')
    AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    AND query_type IN ('SELECT')
    AND execution_status = 'SUCCESS'
ORDER BY total_elapsed_time DESC
LIMIT 100
```
