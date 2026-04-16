# Check: pipeline_execution_audit

Fraction of task runs in the last 7 days whose execution record captures both `query_start_time` and `completed_time`.

## Context

Uses `snowflake.account_usage.task_history` with a 7-day lookback scoped to `{{ database }}.{{ schema }}`. A task run is considered "audited" when it has both a start and a completion timestamp — partial records indicate something interrupted capture (task stopped mid-run, history view staleness, etc.).

`task_history` has approximately 45-minute latency.

Returns NULL (N/A) when no task runs occurred in the window.

## SQL

```sql
WITH task_runs AS (
    SELECT
        name AS task_name,
        query_start_time,
        completed_time
    FROM snowflake.account_usage.task_history
    WHERE scheduled_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
        AND UPPER(database_name) = UPPER('{{ database }}')
        AND UPPER(schema_name)   = UPPER('{{ schema }}')
)
SELECT
    COUNT_IF(query_start_time IS NOT NULL AND completed_time IS NOT NULL) AS audited_runs,
    COUNT(*) AS total_runs,
    COUNT_IF(query_start_time IS NOT NULL AND completed_time IS NOT NULL)::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM task_runs
```
