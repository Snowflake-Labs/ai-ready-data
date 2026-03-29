# Diagnostic: propagation_latency_compliance

Fraction of data pipelines where end-to-end propagation latency meets the defined freshness SLA.

## Context

Uses `SHOW DYNAMIC TABLES` followed by `RESULT_SCAN` to surface each dynamic table's target lag, scheduling state, last refresh timestamp, and computed actual lag in seconds. This two-step pattern is required because dynamic table metadata is not available in `information_schema`.

Tables are ordered by actual lag descending so the worst offenders appear first. A `scheduling_state` of `SUSPENDED` means the table is not actively refreshing and will likely violate its SLA.

Scoped to `{{ database }}.{{ schema }}`.

## SQL

```sql
-- Step 1: Run this first
-- SHOW DYNAMIC TABLES IN SCHEMA {{ database }}.{{ schema }};

-- Step 2: Then query results
SELECT
    "name" AS dynamic_table_name,
    "target_lag" AS target_lag,
    "scheduling_state" AS scheduling_state,
    "last_completed_refresh" AS last_refresh,
    "data_timestamp" AS data_timestamp,
    TIMESTAMPDIFF(
        SECOND, 
        TRY_TO_TIMESTAMP("data_timestamp"), 
        CURRENT_TIMESTAMP()
    ) AS actual_lag_seconds,
    CASE
        WHEN "scheduling_state" = 'RUNNING' THEN 'HEALTHY'
        WHEN "scheduling_state" = 'SUSPENDED' THEN 'SUSPENDED'
        ELSE 'UNKNOWN'
    END AS health_status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY actual_lag_seconds DESC NULLS LAST
```
