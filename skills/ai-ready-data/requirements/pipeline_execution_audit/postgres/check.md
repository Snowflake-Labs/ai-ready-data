# Check: pipeline_execution_audit

Fraction of pipeline execution infrastructure in place for immutable audit records.

## Context

Snowflake provides built-in `task_history` with immutable execution records for every task run. PostgreSQL has no native pipeline/task execution history. The closest equivalents are:

- **`pg_stat_statements`** — Tracks aggregated query statistics (call counts, timing, rows). Provides evidence of query execution but not individual run records.
- **`pgaudit`** — Provides immutable, session-level or object-level audit logging to the PostgreSQL log. This is the strongest analog to Snowflake's execution audit.

This check measures audit infrastructure readiness by checking whether `pg_stat_statements` and/or `pgaudit` are installed. A score of 1.0 means both extensions are present. A score of 0.5 means one is present. A score of 0.0 means neither is installed. This checks for audit *capability*, not individual pipeline records.

## SQL

```sql
WITH audit_extensions AS (
    SELECT
        COUNT(*) FILTER (WHERE extname = 'pg_stat_statements') AS has_pgss,
        COUNT(*) FILTER (WHERE extname = 'pgaudit') AS has_pgaudit
    FROM pg_extension
    WHERE extname IN ('pg_stat_statements', 'pgaudit')
)
SELECT
    has_pgss AS pg_stat_statements_installed,
    has_pgaudit AS pgaudit_installed,
    (has_pgss + has_pgaudit)::NUMERIC / 2.0 AS value
FROM audit_extensions
```
