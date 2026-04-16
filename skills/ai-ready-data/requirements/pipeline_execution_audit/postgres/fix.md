# Fix: pipeline_execution_audit

Install and configure audit infrastructure for capturing pipeline execution records.

## Context

PostgreSQL requires explicit extension installation and configuration for audit logging. Unlike Snowflake's built-in `task_history`, PostgreSQL audit coverage is opt-in. The recommended approach is to install both `pgaudit` (for immutable audit logs) and `pg_stat_statements` (for query statistics).

## Remediation: Install pgaudit

`pgaudit` provides session and object-level audit logging to the PostgreSQL log files, creating immutable execution records.

```sql
CREATE EXTENSION IF NOT EXISTS pgaudit;
```

Add to `postgresql.conf`:

```
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'write, ddl'
pgaudit.log_relation = on
pgaudit.log_statement_once = on
```

Restart PostgreSQL after changing `shared_preload_libraries`.

## Remediation: Install pg_stat_statements

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Add to `postgresql.conf`:

```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
pg_stat_statements.max = 10000
```

## Remediation: Configure statement logging

For environments where extensions cannot be installed, enable native statement logging:

```
log_statement = 'mod'
log_min_duration_statement = 0
log_line_prefix = '%t [%p] %u@%d app=%a '
```

This logs all data-modifying statements with timestamps, user, database, and application name — providing a basic audit trail in server logs.
