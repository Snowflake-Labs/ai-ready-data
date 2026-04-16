# Fix: propagation_latency_compliance

Restore on-time propagation for dynamic tables whose end-to-end lag exceeds the SLA.

## Context

Dynamic tables carry a `TARGET_LAG` and a `data_timestamp` that together describe their freshness guarantee. Non-compliance is typically one of three root causes: the dynamic table is suspended, the warehouse is undersized for the target, or the upstream pipeline is not a dynamic table at all and has no declarative lag guarantee.

`account_usage.query_history` and `DYNAMIC_TABLE_REFRESH_HISTORY` have approximately 45-minute latency — the check may not reflect a resumed or resized table for that window.

## Fix: Resume a suspended dynamic table

```sql
ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.{{ asset }} RESUME;
```

## Fix: Adjust target lag or warehouse

Use when actual lag consistently exceeds the current target. Either relax the target to match operational reality, or attach a larger warehouse:

```sql
ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.{{ asset }} SET TARGET_LAG = '{{ target_lag }}';
```

```sql
ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.{{ asset }} SET WAREHOUSE = {{ warehouse }};
```

## Fix: Wrap an unmanaged pipeline in a dynamic table

Use when data is loaded via external ETL without declarative freshness tracking. Wrapping downstream transformations as a dynamic table gives Snowflake explicit lag guarantees:

```sql
CREATE OR REPLACE DYNAMIC TABLE {{ database }}.{{ schema }}.{{ asset }}
    TARGET_LAG = '{{ target_lag }}'
    WAREHOUSE = {{ warehouse }}
AS
    SELECT * FROM {{ source_namespace }}.{{ source_asset }};
```

## Monitor refresh history

For ongoing compliance tracking:

```sql
SELECT *
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME => '{{ database }}.{{ schema }}.{{ asset }}'
))
ORDER BY REFRESH_START_TIME DESC
LIMIT 20;
```
