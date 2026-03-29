# Diagnostic: agent_attribution

Recent data modification queries with their attribution details.

## Context

Shows the most recent 100 write operations against the schema with user, role, warehouse, query tag, and an attribution status label. Use this to identify which pipelines or users are generating unattributed writes.

Queries marked `UNATTRIBUTED` have no `QUERY_TAG` set. The `user_name` and `role_name` columns still provide some traceability, but `QUERY_TAG` is the attribution signal that matters for agentic workloads because it distinguishes between different pipelines or agents running under the same service account.

`account_usage.query_history` has approximately 45-minute latency.

## SQL

```sql
SELECT
    query_id,
    query_type,
    user_name,
    role_name,
    warehouse_name,
    query_tag,
    start_time,
    execution_status,
    rows_produced,
    CASE
        WHEN query_tag IS NOT NULL AND query_tag != '' THEN 'ATTRIBUTED'
        ELSE 'UNATTRIBUTED'
    END AS attribution_status
FROM snowflake.account_usage.query_history
WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
    AND query_type IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE', 'COPY', 'CREATE_TABLE_AS_SELECT')
    AND UPPER(database_name) = UPPER('{{ database }}')
    AND UPPER(schema_name) = UPPER('{{ schema }}')
ORDER BY start_time DESC
LIMIT 100
```
