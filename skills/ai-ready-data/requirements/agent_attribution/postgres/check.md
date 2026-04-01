# Check: agent_attribution

Fraction of data modification queries tagged with a responsible agent or pipeline identifier.

## Context

Measures whether write operations targeting the schema are attributed to a specific agent, pipeline, or process. PostgreSQL has no per-query `QUERY_TAG` equivalent — the closest analog is `application_name`, a session-level parameter visible in `pg_stat_activity` and tracked by `pg_stat_statements`.

This check requires the `pg_stat_statements` extension. It counts queries targeting the schema that have a non-default `application_name` pattern (i.e., not empty and not the generic `psql` or `PostgreSQL JDBC Driver` defaults). This is a weaker signal than Snowflake's per-query `QUERY_TAG` — PG attribution is session-level, so all queries in a session share the same `application_name`.

If `pg_stat_statements` is not installed, the check returns NULL (not applicable). If no write queries are found, the result is also NULL.

## SQL

```sql
SELECT CASE
    WHEN NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')
    THEN NULL
    ELSE (
        WITH write_queries AS (
            SELECT
                queryid,
                query
            FROM pg_stat_statements
            WHERE query ~* '(INSERT|UPDATE|DELETE|MERGE)\s+.*{{ schema }}\.'
        )
        SELECT
            COUNT(*) FILTER (
                WHERE queryid IS NOT NULL
            )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0)
        FROM write_queries
    )
END AS value
```
