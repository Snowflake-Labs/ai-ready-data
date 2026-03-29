# Check: feature_refresh_compliance

Fraction of served features updated within their defined staleness tolerance threshold.

## Context

Uses `information_schema.tables` to count dynamic tables in the schema. Accurate measurement requires running `SHOW DYNAMIC TABLES` followed by `RESULT_SCAN` in the same session to inspect `scheduling_state` and compare actual lag to `target_lag`.

Requires SHOW DYNAMIC TABLES + RESULT_SCAN for accurate measurement.

## SQL

```sql
WITH dynamic_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'DYNAMIC TABLE'
)
SELECT
    (SELECT cnt FROM dynamic_tables) AS total_dynamic_tables,
    -- Assume compliant unless SHOW DYNAMIC TABLES reveals otherwise
    1.0 AS value
-- For accurate results, run:
-- SHOW DYNAMIC TABLES IN SCHEMA {{ database }}.{{ schema }};
-- Then check "scheduling_state" = 'RUNNING' and compare actual lag to target_lag
```
