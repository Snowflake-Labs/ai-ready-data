# Check: serving_latency_compliance

Fraction of successful SELECT queries that **read from tables in the target schema** and completed within the configured latency SLA.

## Context

Attribution uses `snowflake.account_usage.access_history` — specifically the `direct_objects_accessed` array — to identify queries that actually read a table in `{{ database }}.{{ schema }}`. This is more accurate than filtering `query_history.schema_name`, which records the session's current schema (a user sitting in `ANALYTICS.TMP` querying `PRODUCT.ORDERS` would otherwise be miscredited to `TMP`).

Caveats:

- `access_history` has ~2-hour latency and requires `IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE`.
- Only tables are considered (objectDomain = 'Table'); view-based lookups appear with the underlying tables in `base_objects_accessed` — swap to that array if you need view-level attribution.
- 7-day lookback window; override via a profile if you need longer retrospectives.
- `total_elapsed_time` is in milliseconds — `{{ latency_threshold_ms }}` should be provided in the same unit.

Returns NULL (N/A) when no qualifying queries occurred in the window.

## SQL

```sql
WITH scoped_queries AS (
    SELECT DISTINCT ah.query_id
    FROM snowflake.account_usage.access_history ah,
         LATERAL FLATTEN(input => ah.direct_objects_accessed) obj
    WHERE ah.query_start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
      AND obj.value:objectDomain::STRING = 'Table'
      AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
      AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
),
latency AS (
    SELECT qh.query_id, qh.total_elapsed_time
    FROM snowflake.account_usage.query_history qh
    JOIN scoped_queries sq USING (query_id)
    WHERE qh.query_type = 'SELECT'
      AND qh.execution_status = 'SUCCESS'
      AND qh.start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
)
SELECT
    COUNT_IF(total_elapsed_time <= {{ latency_threshold_ms }}) AS compliant_queries,
    COUNT(*) AS total_queries,
    COUNT_IF(total_elapsed_time <= {{ latency_threshold_ms }})::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM latency
```
