# Diagnostic: pipeline_execution_audit

Shows audit infrastructure status and recent query execution statistics.

## Context

Enumerates installed audit-related extensions and their configuration, then shows the most active query patterns from `pg_stat_statements` (if available) to illustrate current audit coverage. This helps identify whether pipeline queries are being captured and what audit gaps exist.

## SQL

### Audit infrastructure status

```sql
SELECT
    e.extname AS extension_name,
    e.extversion AS version,
    CASE
        WHEN e.extname = 'pgaudit' THEN 'Immutable audit logging'
        WHEN e.extname = 'pg_stat_statements' THEN 'Query statistics tracking'
        ELSE 'Other'
    END AS purpose
FROM pg_extension e
WHERE e.extname IN ('pgaudit', 'pg_stat_statements')

UNION ALL

SELECT
    'log_statement' AS extension_name,
    current_setting('log_statement', true) AS version,
    CASE current_setting('log_statement', true)
        WHEN 'all' THEN 'All statements logged'
        WHEN 'mod' THEN 'Data-modifying statements logged'
        WHEN 'ddl' THEN 'DDL statements only'
        ELSE 'No statement logging'
    END AS purpose
```

### Recent query patterns (requires pg_stat_statements)

```sql
SELECT
    queryid,
    LEFT(query, 200) AS query_pattern,
    calls AS execution_count,
    total_exec_time / 1000 AS total_exec_seconds,
    rows AS total_rows_affected,
    CASE
        WHEN query ~* '^(INSERT|UPDATE|DELETE|MERGE)' THEN 'WRITE'
        WHEN query ~* '^(SELECT|WITH)' THEN 'READ'
        WHEN query ~* '^(CREATE|ALTER|DROP)' THEN 'DDL'
        ELSE 'OTHER'
    END AS query_type,
    CASE
        WHEN query ~* '{{ schema }}\.' THEN 'IN_SCOPE'
        ELSE 'OUT_OF_SCOPE'
    END AS schema_relevance
FROM pg_stat_statements
WHERE query ~* '{{ schema }}\.'
ORDER BY calls DESC
LIMIT 50
```
