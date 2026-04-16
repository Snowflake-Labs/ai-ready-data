# Check: agent_attribution

Fraction of data modification queries tagged with a responsible agent or pipeline identifier.

## Context

Measures whether write operations against the schema carry meaningful attribution via `application_name` or query comment conventions. Uses `pg_stat_statements` (if installed) to inspect recent query patterns targeting the schema.

PostgreSQL does not have a per-query `QUERY_TAG` equivalent. The closest analog is the session-level `application_name` parameter, which is set on the connection and appears in `pg_stat_activity` and `pg_stat_statements`. Attribution is therefore coarser than Snowflake — it identifies the application or pipeline process, not individual query runs.

If `pg_stat_statements` is not installed, the check returns NULL (not applicable). When available, it counts the fraction of write queries (INSERT, UPDATE, DELETE, MERGE) targeting the schema that originated from sessions with a non-default `application_name`.

A score of 1.0 means every captured write query came from a session with a meaningful `application_name`. A score of 0.0 means all writes used the default `application_name` (typically empty or `psql`).

## SQL

```sql
SELECT CASE
    WHEN NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_stat_statements')
    THEN NULL
    ELSE (
        WITH write_queries AS (
            SELECT
                queryid,
                query,
                calls
            FROM pg_stat_statements
            WHERE query ~* '(INSERT|UPDATE|DELETE|MERGE)\s+INTO\s+{{ schema }}\.'
               OR query ~* '(UPDATE|DELETE\s+FROM)\s+{{ schema }}\.'
        ),
        attributed AS (
            SELECT SUM(calls) AS cnt
            FROM write_queries
            WHERE queryid IN (
                SELECT queryid FROM pg_stat_statements
                WHERE query ~* '/\*.*agent=|pipeline=|app=.*\*/'
            )
        ),
        total AS (
            SELECT SUM(calls) AS cnt FROM write_queries
        )
        SELECT attributed.cnt::NUMERIC / NULLIF(total.cnt::NUMERIC, 0)
        FROM attributed, total
    )
END AS value
```
