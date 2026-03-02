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
        AND database_name = '{{ container }}'
        AND schema_name = '{{ namespace }}'
),
audited_runs AS (
    SELECT * FROM task_runs
    WHERE query_start_time IS NOT NULL AND completed_time IS NOT NULL
)
SELECT
    (SELECT COUNT(*) FROM audited_runs) AS audited_runs,
    (SELECT COUNT(*) FROM task_runs) AS total_runs,
    CASE
        WHEN (SELECT COUNT(*) FROM task_runs) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM audited_runs)::FLOAT / 
             (SELECT COUNT(*) FROM task_runs)::FLOAT
    END AS value
