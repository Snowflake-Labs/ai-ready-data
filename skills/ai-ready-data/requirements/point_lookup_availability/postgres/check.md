# Check: point_lookup_availability

Fraction of tables accessible via low-latency key-based point lookups.

## Context

In PostgreSQL, efficient point lookups require a primary key or unique B-tree index on the lookup column(s). Unlike Snowflake — where point lookup readiness depends on clustering keys and search optimization — PostgreSQL primary keys and unique indexes provide direct O(log N) access to individual rows via the B-tree.

This check counts tables that have at least one primary key or unique index, which enables single-row lookups without a sequential scan.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
pk_tables AS (
    SELECT COUNT(DISTINCT c.oid) AS cnt
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND (i.indisprimary OR i.indisunique)
)
SELECT
    pk_tables.cnt AS tables_with_pk_or_unique,
    table_count.cnt AS total_tables,
    pk_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, pk_tables
```
