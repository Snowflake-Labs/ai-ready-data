# Check: propagation_latency_compliance

Fraction of data pipelines where end-to-end propagation latency meets the defined freshness SLA.

## Context

PostgreSQL does not have Snowflake's dynamic tables with built-in target lag tracking. Instead, this check uses a comment-based heuristic to detect tables that have freshness SLA documentation, combined with checking for materialized views (PostgreSQL's closest analog to dynamic tables with managed refresh).

A table is considered covered if it is a materialized view or if its comment contains freshness-related keywords: `freshness_sla`, `target_lag`, `refresh_interval`, `propagation_sla`.

For real-time pipeline monitoring, consider using logical replication slots (`pg_replication_slots`) or custom pipeline metadata tables.

## SQL

```sql
WITH base_tables AS (
    SELECT COUNT(*) AS cnt
    FROM information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
matviews AS (
    SELECT COUNT(*) AS cnt
    FROM pg_matviews
    WHERE schemaname = '{{ schema }}'
),
freshness_documented AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind IN ('r', 'm')
        AND obj_description(c.oid) IS NOT NULL
        AND (
            LOWER(obj_description(c.oid)) LIKE '%freshness_sla%'
            OR LOWER(obj_description(c.oid)) LIKE '%target_lag%'
            OR LOWER(obj_description(c.oid)) LIKE '%refresh_interval%'
            OR LOWER(obj_description(c.oid)) LIKE '%propagation_sla%'
        )
)
SELECT
    matviews.cnt AS materialized_views,
    freshness_documented.cnt AS freshness_documented_tables,
    base_tables.cnt AS total_base_tables,
    CASE
        WHEN base_tables.cnt = 0 THEN 1.0
        ELSE (matviews.cnt + freshness_documented.cnt)::NUMERIC / base_tables.cnt::NUMERIC
    END AS value
FROM base_tables, matviews, freshness_documented
```
