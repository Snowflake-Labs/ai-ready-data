# Check: pipeline_execution_audit

Fraction of pipeline runs with immutable execution records capturing inputs, parameters, outputs, and completion status.

## Context

Uses `snowflake.account_usage.task_history` with a 7-day lookback window scoped to the target database and schema. A task run is considered "audited" when both `query_start_time` and `completed_time` are present. A score of 1.0 means every task run in the window has a complete execution record.

`task_history` has approximately 45-minute latency — very recent runs may not yet appear.

## SQL

```sql
-- check-pipeline-execution-audit.sql
-- Checks if pipeline executions (tasks) have audit records
-- Returns: value (float 0-1) - fraction of task runs with complete audit

WITH task_runs AS (
    SELECT
        name AS task_name,
        state,
        scheduled_time,
        query_start_time,
        completed_time,
        error_code,
        error_message
    FROM snowflake.account_usage.task_history
    WHERE scheduled_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND UPPER(database_name) = UPPER('{{ database }}')
        AND UPPER(schema_name) = UPPER('{{ schema }}')
),
audited_runs AS (
    SELECT * FROM task_runs
    WHERE query_start_time IS NOT NULL AND completed_time IS NOT NULL
)
SELECT
    (SELECT COUNT(*) FROM audited_runs) AS audited_runs,
    (SELECT COUNT(*) FROM task_runs) AS total_runs,
    (SELECT COUNT(*) FROM audited_runs)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM task_runs)::FLOAT, 0) AS value
```
