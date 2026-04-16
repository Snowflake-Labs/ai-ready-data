# Check: feature_refresh_compliance

Fraction of dynamic tables in the schema whose most recent refresh is within the configured staleness tolerance and whose scheduling state is active.

## Context

Served features in Snowflake are typically materialized via dynamic tables. A dynamic table is "compliant" when (a) its `scheduling_state` indicates an active refresh schedule (not suspended), and (b) its `data_timestamp` (the logical freshness watermark) is within the caller's staleness tolerance (`{{ staleness_threshold_hours }}`).

Requires `SHOW DYNAMIC TABLES` + `RESULT_SCAN` in the **same session** — `scheduling_state` and `data_timestamp` are not exposed in `information_schema.tables`.

Returns NULL (N/A) when the schema contains no dynamic tables.

## SQL

```sql
SHOW DYNAMIC TABLES IN SCHEMA {{ database }}.{{ schema }};

WITH dt AS (
    SELECT
        "name" AS table_name,
        "scheduling_state" AS scheduling_state,
        "data_timestamp" AS data_timestamp
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
)
SELECT
    COUNT_IF(
        scheduling_state ILIKE '%RUNNING%'
        AND data_timestamp IS NOT NULL
        AND DATEDIFF('hour', data_timestamp::TIMESTAMP_NTZ, CURRENT_TIMESTAMP()) <= {{ staleness_threshold_hours }}
    ) AS fresh_features,
    COUNT(*) AS total_dynamic_tables,
    COUNT_IF(
        scheduling_state ILIKE '%RUNNING%'
        AND data_timestamp IS NOT NULL
        AND DATEDIFF('hour', data_timestamp::TIMESTAMP_NTZ, CURRENT_TIMESTAMP()) <= {{ staleness_threshold_hours }}
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM dt
```
