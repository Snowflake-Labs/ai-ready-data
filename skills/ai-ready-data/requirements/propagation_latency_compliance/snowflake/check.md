# Check: propagation_latency_compliance

Fraction of dynamic tables whose end-to-end propagation latency (time between `data_timestamp` and now) is within the configured freshness SLA.

## Context

Dynamic tables are Snowflake's declarative pipeline primitive. Each one carries a `target_lag` and a `data_timestamp` (the point-in-time of the data currently materialized). This check compares the observed lag (`now - data_timestamp`) against a caller-supplied `{{ freshness_threshold_hours }}` — a policy-level SLA that may be tighter or looser than the dynamic table's own declared `target_lag`.

Requires `SHOW DYNAMIC TABLES` + `RESULT_SCAN` in the **same session** — `data_timestamp` is not exposed in `information_schema.tables`.

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
        data_timestamp IS NOT NULL
        AND DATEDIFF('hour', data_timestamp::TIMESTAMP_NTZ, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }}
    ) AS within_sla,
    COUNT(*) AS total_dynamic_tables,
    COUNT_IF(
        data_timestamp IS NOT NULL
        AND DATEDIFF('hour', data_timestamp::TIMESTAMP_NTZ, CURRENT_TIMESTAMP()) <= {{ freshness_threshold_hours }}
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM dt
```
