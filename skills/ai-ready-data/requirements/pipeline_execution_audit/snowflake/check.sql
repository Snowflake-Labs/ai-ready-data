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
