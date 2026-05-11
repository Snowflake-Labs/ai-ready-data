# Check: pipeline_execution_audit

Fraction of audit infrastructure in place for capturing immutable pipeline execution records.

## Context

PostgreSQL does not have a built-in `task_history` like Snowflake. Pipeline execution auditing in PostgreSQL relies on extensions and logging configuration:

1. **`pgaudit`** — Provides session and object-level audit logging of SQL statements to the PostgreSQL log. This is the closest equivalent to immutable execution records.
2. **`pg_stat_statements`** — Tracks query execution statistics (call counts, timing, rows). Useful for understanding query patterns but not a true audit trail — data is cumulative and resets on server restart or manual reset.
3. **PostgreSQL logging** — Native `log_statement` and `log_min_duration_statement` settings capture queries to server logs.

This check scores infrastructure readiness: it verifies whether `pgaudit` and/or `pg_stat_statements` are installed, and whether logging is configured for audit coverage. A score of 1.0 means full audit infrastructure is present. A score of 0.0 means no audit extensions are installed.

## SQL

```sql
WITH audit_checks AS (
    SELECT
        EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgaudit') AS has_pgaudit,
        EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements') AS has_pg_stat_statements,
        current_setting('log_statement', true) AS log_statement_setting
),
score AS (
    SELECT
        CASE
            WHEN has_pgaudit AND has_pg_stat_statements THEN 1.0
            WHEN has_pgaudit OR has_pg_stat_statements THEN 0.5
            WHEN log_statement_setting IN ('all', 'mod') THEN 0.25
            ELSE 0.0
        END AS value,
        has_pgaudit,
        has_pg_stat_statements,
        log_statement_setting
    FROM audit_checks
)
SELECT
    has_pgaudit,
    has_pg_stat_statements,
    log_statement_setting,
    value
FROM score
```
