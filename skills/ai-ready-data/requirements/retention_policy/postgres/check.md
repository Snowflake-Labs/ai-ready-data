# Check: retention_policy

Fraction of datasets with defined and enforced data retention and deletion schedules.

## Context

PostgreSQL has no native tag-based retention system like Snowflake's `tag_references`. Retention policy is detected through two signals:

1. **Table comments** — checks `obj_description()` for retention-related keywords (`retention`, `ttl`, `expire`, `purge`, `archive`, `lifecycle`). This indicates documented retention intent.
2. **Range partitioning** — checks `pg_partitioned_table` for tables with range-based partitioning, which is a common pattern for lifecycle management (e.g., dropping old partitions). A partitioned table with range strategy indicates active retention infrastructure.

A table counts as having a retention policy if it has either a retention-keyword comment OR is a range-partitioned table.

Returns a float 0–1 representing the fraction of in-scope tables with retention coverage.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        c.oid,
        c.relname AS table_name,
        c.relkind
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind IN ('r', 'p')
),
tables_with_retention AS (
    SELECT DISTINCT t.oid
    FROM tables_in_scope t
    LEFT JOIN pg_partitioned_table pt ON pt.partrelid = t.oid
    WHERE
        (
            obj_description(t.oid) IS NOT NULL
            AND (
                LOWER(obj_description(t.oid)) LIKE '%retention%'
                OR LOWER(obj_description(t.oid)) LIKE '%ttl%'
                OR LOWER(obj_description(t.oid)) LIKE '%expire%'
                OR LOWER(obj_description(t.oid)) LIKE '%purge%'
                OR LOWER(obj_description(t.oid)) LIKE '%archive%'
                OR LOWER(obj_description(t.oid)) LIKE '%lifecycle%'
            )
        )
        OR (t.relkind = 'p' AND pt.partstrat = 'r')
)
SELECT
    (SELECT COUNT(*) FROM tables_with_retention) AS tables_with_retention,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_retention)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
```
