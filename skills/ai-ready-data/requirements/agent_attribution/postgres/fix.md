# Fix: agent_attribution

Establish query attribution conventions for pipelines and agents that write to this schema.

## Context

PostgreSQL does not have a per-query `QUERY_TAG` like Snowflake. Attribution requires a combination of connection-level and query-level conventions:

1. **`application_name`** — Session-level parameter set in the connection string. Identifies the application or pipeline process. This is the primary attribution mechanism in PostgreSQL.
2. **SQL comments** — Embedding structured comments (e.g., `/* agent=daily_loader; run_id=2024-01-15-001 */`) in queries provides per-query attribution that survives into `pg_stat_statements` and logs.
3. **`pgaudit`** — Extension that provides immutable audit logging of all SQL statements, capturing the `application_name` for each.

This is not a one-time DDL fix — it requires changes to pipeline and agent connection configurations and query templates.

## Remediation: Set application_name in connection strings

Each pipeline or agent should set `application_name` in its connection string:

```
postgresql://user:pass@host:5432/db?application_name=pipeline_daily_load
```

Or set it per-session after connecting:

```sql
SET application_name = 'pipeline_daily_load';
```

## Remediation: Add SQL comment attribution

Embed structured comments in write queries for per-query attribution:

```sql
/* agent=daily_loader; run_id=2024-01-15-001 */
INSERT INTO {{ schema }}.{{ asset }} (col1, col2) VALUES ($1, $2);
```

## Remediation: Install pg_stat_statements

Ensure `pg_stat_statements` is installed and configured to capture query patterns:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Add to `postgresql.conf`:

```
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.track = all
```
