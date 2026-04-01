# Fix: agent_attribution

Establish application naming conventions for pipelines and agents that write to this schema.

## Context

PostgreSQL's `application_name` is a session-level parameter — the closest analog to Snowflake's `QUERY_TAG`. Unlike `QUERY_TAG`, which can be changed per-query within a session, `application_name` applies to the entire connection. This means attribution granularity is per-connection, not per-query.

Remediation requires changes to pipeline and agent connection configuration. Every process that writes to this schema should set `application_name` in its connection string or at session start.

## Remediation: Set application_name in connection strings

The most reliable approach is to set `application_name` in the connection string itself:

```
postgresql://user:pass@host:5432/db?application_name=pipeline%3Ddaily_load
```

## Remediation: Set application_name at session start

If the connection string cannot be modified, set it at session start before any write operations:

```sql
SET application_name = '{{ application_name }}';
```

A good `application_name` format includes the pipeline or agent name and optionally a run identifier, e.g. `pipeline=daily_load;run_id=2024-01-15-001` or `agent=rag_indexer;session=abc123`.

## Remediation: Install pg_stat_statements

If `pg_stat_statements` is not installed, install it to enable query tracking:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Note: `pg_stat_statements` must also be added to `shared_preload_libraries` in `postgresql.conf`, which requires a server restart.

## Remediation: Verify attribution is working

After deploying `application_name` conventions, check active sessions:

```sql
SELECT pid, usename, application_name, state
FROM pg_stat_activity
WHERE datname = current_database();
```
