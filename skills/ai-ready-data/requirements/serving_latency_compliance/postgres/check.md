# Check: serving_latency_compliance

Fraction of data serving queries meeting their defined latency SLA.

## Context

PostgreSQL does not have a built-in query history like Snowflake's `account_usage.query_history`. This check requires the `pg_stat_statements` extension, which must be enabled (`CREATE EXTENSION IF NOT EXISTS pg_stat_statements`).

`pg_stat_statements` tracks cumulative statistics per query pattern (not individual executions). The check uses `mean_exec_time` as a proxy — if mean execution time is within the SLA, the query pattern is considered compliant. For p99 tracking, use `pg_stat_statements` v1.8+ which includes min/max/stddev fields.

The check is schema-scoped by filtering on query patterns that reference tables in `{{ schema }}`. This is a heuristic — queries referencing multiple schemas may be counted multiple times or missed.

## SQL

```sql
WITH query_stats AS (
    SELECT
        COUNT(*) AS total_query_patterns,
        COUNT(*) FILTER (WHERE mean_exec_time <= {{ latency_threshold_ms }}) AS compliant_patterns
    FROM pg_stat_statements s
    JOIN pg_database d ON d.oid = s.dbid
    WHERE d.datname = current_database()
        AND s.query ~* '{{ schema }}\.'
        AND s.calls > 0
)
SELECT
    compliant_patterns,
    total_query_patterns,
    compliant_patterns::NUMERIC / NULLIF(total_query_patterns::NUMERIC, 0) AS value
FROM query_stats
```
