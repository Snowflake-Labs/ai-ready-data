# Fix: pipeline_execution_audit

Install audit extensions and configure logging for pipeline execution tracking.

## Context

PostgreSQL does not have built-in pipeline execution history. Achieving audit coverage requires installing extensions and configuring logging. There are two complementary approaches:

1. **`pg_stat_statements`** — Lightweight query statistics. Tracks call counts, timing, and rows per normalized query. No individual run records, but sufficient for activity monitoring.
2. **`pgaudit`** — Full audit logging. Writes individual statement execution records to the PostgreSQL log. Provides immutable records but requires log management infrastructure.

Both extensions require entries in `shared_preload_libraries` in `postgresql.conf`, which necessitates a server restart.

## Remediation: Install pg_stat_statements

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Add to `postgresql.conf`:
```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```

## Remediation: Install pgaudit

```sql
CREATE EXTENSION IF NOT EXISTS pgaudit;
```

Add to `postgresql.conf`:
```
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'write, ddl'
pgaudit.log_catalog = off
```

The `pgaudit.log = 'write, ddl'` setting logs all data modification and DDL statements — the operations most relevant to pipeline execution auditing.

## Remediation: Create an application-level audit table

For pipelines that need structured run records (comparable to Snowflake's `task_history`), create an explicit audit table:

```sql
CREATE TABLE IF NOT EXISTS {{ schema }}.pipeline_execution_log (
    execution_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pipeline_name   TEXT NOT NULL,
    run_id          TEXT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at    TIMESTAMPTZ,
    status          TEXT CHECK (status IN ('RUNNING', 'SUCCEEDED', 'FAILED')),
    rows_affected   BIGINT,
    error_message   TEXT
);
```
