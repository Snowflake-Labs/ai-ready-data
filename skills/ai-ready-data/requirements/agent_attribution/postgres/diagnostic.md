# Diagnostic: agent_attribution

Recent data modification query patterns with attribution details.

## Context

Shows distinct write query patterns from `pg_stat_statements` targeting the schema, along with call counts and total rows affected. Unlike Snowflake's `query_history` which logs individual executions with `QUERY_TAG`, `pg_stat_statements` aggregates by normalized query text — so this diagnostic shows query patterns, not individual runs.

To see currently running sessions and their `application_name`, the second query checks `pg_stat_activity`. Sessions with a default or empty `application_name` are flagged as `UNATTRIBUTED`.

Requires `pg_stat_statements` extension and `pg_read_all_stats` role.

## SQL

### Query patterns targeting the schema

```sql
SELECT
    queryid,
    LEFT(query, 200) AS query_preview,
    calls,
    rows,
    CASE
        WHEN queryid IS NOT NULL THEN 'TRACKED'
        ELSE 'UNTRACKED'
    END AS tracking_status
FROM pg_stat_statements
WHERE query ~* '(INSERT|UPDATE|DELETE|MERGE)\s+.*{{ schema }}\.'
ORDER BY calls DESC
LIMIT 100
```

### Active sessions with attribution status

```sql
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    backend_start,
    state,
    LEFT(query, 200) AS current_query,
    CASE
        WHEN application_name IS NOT NULL
            AND application_name != ''
            AND application_name NOT IN ('psql', 'PostgreSQL JDBC Driver', 'pgAdmin 4 - DB:*')
        THEN 'ATTRIBUTED'
        ELSE 'UNATTRIBUTED'
    END AS attribution_status
FROM pg_stat_activity
WHERE datname = current_database()
    AND pid != pg_backend_pid()
ORDER BY attribution_status, backend_start DESC
```
