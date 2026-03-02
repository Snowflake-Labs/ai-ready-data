-- diagnostic-pipeline-execution-audit.sql
-- Shows recent task executions with audit details
-- Returns: task runs with execution metadata

SELECT
    name AS task_name,
    state,
    scheduled_time,
    query_start_time,
    completed_time,
    TIMESTAMPDIFF(second, query_start_time, completed_time) AS duration_seconds,
    error_code,
    error_message,
    CASE
        WHEN query_start_time IS NOT NULL AND completed_time IS NOT NULL THEN 'COMPLETE_AUDIT'
        WHEN query_start_time IS NOT NULL THEN 'PARTIAL_AUDIT'
        ELSE 'NO_AUDIT'
    END AS audit_status,
    CASE
        WHEN state = 'SUCCEEDED' THEN 'Execution completed successfully'
        WHEN state = 'FAILED' THEN 'Check error_message for failure reason'
        WHEN state = 'SKIPPED' THEN 'Task skipped - check schedule'
        ELSE 'Review task state'
    END AS recommendation
FROM snowflake.account_usage.task_history
WHERE scheduled_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND database_name = '{{ database }}'
    AND schema_name = '{{ schema }}'
ORDER BY scheduled_time DESC
LIMIT 100
