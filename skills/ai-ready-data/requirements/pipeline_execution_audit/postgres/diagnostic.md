# Diagnostic: pipeline_execution_audit

Shows audit infrastructure status and query activity for the schema.

## Context

Reports on the presence of audit extensions and, if `pg_stat_statements` is available, shows the most active query patterns targeting the schema. This helps identify which pipelines are running and whether their execution is being tracked.

Unlike Snowflake's `task_history` which provides per-run records with timing and status, `pg_stat_statements` only provides aggregated statistics per normalized query. Individual run records require `pgaudit` log analysis or an application-level audit table.

## SQL

### Audit infrastructure status

```sql
SELECT
    extname AS extension_name,
    extversion AS version,
    CASE extname
        WHEN 'pg_stat_statements' THEN 'Query statistics tracking'
        WHEN 'pgaudit' THEN 'Immutable audit logging'
        ELSE 'Other'
    END AS purpose
FROM pg_extension
WHERE extname IN ('pg_stat_statements', 'pgaudit')

UNION ALL

SELECT
    missing.extname,
    NULL AS version,
    'NOT INSTALLED — ' || missing.purpose AS purpose
FROM (VALUES
    ('pg_stat_statements', 'Query statistics tracking'),
    ('pgaudit', 'Immutable audit logging')
) AS missing(extname, purpose)
WHERE missing.extname NOT IN (SELECT extname FROM pg_extension)
```

### Query activity for the schema (requires pg_stat_statements)

```sql
SELECT
    queryid,
    LEFT(query, 300) AS query_preview,
    calls,
    total_exec_time::NUMERIC / 1000 AS total_exec_seconds,
    mean_exec_time::NUMERIC / 1000 AS mean_exec_seconds,
    rows,
    CASE
        WHEN calls > 0 AND rows > 0 THEN 'ACTIVE'
        ELSE 'INACTIVE'
    END AS activity_status
FROM pg_stat_statements
WHERE query ~* '{{ schema }}\.'
ORDER BY calls DESC
LIMIT 50
```
