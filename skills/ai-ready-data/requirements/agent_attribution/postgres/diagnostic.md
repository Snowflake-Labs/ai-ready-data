# Diagnostic: agent_attribution

Recent data modification query patterns with their attribution details.

## Context

Shows the most common write query patterns against the schema from `pg_stat_statements`, along with total call counts and whether the queries carry attribution markers (SQL comments with agent/pipeline identifiers).

PostgreSQL's `pg_stat_statements` normalizes queries (replacing literal values with `$1`, `$2`, etc.), so this shows query _patterns_ rather than individual executions. The `calls` column indicates how many times each pattern was executed.

If `pg_stat_statements` is not available, falls back to `pg_stat_activity` for currently running sessions, which is a much narrower view.

## SQL

### With pg_stat_statements

```sql
SELECT
    queryid,
    LEFT(query, 200) AS query_pattern,
    calls AS execution_count,
    CASE
        WHEN query ~* '/\*.*agent=|pipeline=|app=.*\*/' THEN 'ATTRIBUTED'
        ELSE 'UNATTRIBUTED'
    END AS attribution_status,
    total_exec_time / 1000 AS total_exec_seconds,
    rows AS total_rows_affected
FROM pg_stat_statements
WHERE query ~* '(INSERT|UPDATE|DELETE|MERGE)\s+INTO\s+{{ schema }}\.'
   OR query ~* '(UPDATE|DELETE\s+FROM)\s+{{ schema }}\.'
ORDER BY calls DESC
LIMIT 50
```

### Fallback: current sessions only

```sql
SELECT
    pid,
    usename,
    application_name,
    LEFT(query, 200) AS current_query,
    state,
    CASE
        WHEN application_name IS NOT NULL
            AND application_name NOT IN ('', 'psql', 'pgAdmin')
        THEN 'ATTRIBUTED'
        ELSE 'UNATTRIBUTED'
    END AS attribution_status,
    backend_start,
    query_start
FROM pg_stat_activity
WHERE datname = current_database()
    AND query ~* '(INSERT|UPDATE|DELETE|MERGE).*{{ schema }}\.'
ORDER BY query_start DESC NULLS LAST
```
