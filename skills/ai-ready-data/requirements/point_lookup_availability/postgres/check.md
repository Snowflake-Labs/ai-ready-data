# Check: point_lookup_availability

Fraction of tables accessible via low-latency key-based point lookups.

## Context

A table supports efficient point lookups when it has a primary key or unique B-tree index, enabling O(log N) key-based access instead of sequential scans. This check counts the fraction of base tables in the schema that have at least one primary key or unique index.

Unlike Snowflake, where point lookup availability depends on clustering keys and search optimization (both requiring `SHOW TABLES`), PostgreSQL exposes this information directly through `pg_index`, making the check straightforward and accurate.

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
    SELECT COUNT(DISTINCT i.indrelid) AS cnt
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND (i.indisprimary OR i.indisunique)
)
SELECT
    pk_tables.cnt    AS tables_with_pk_or_unique,
    table_count.cnt  AS total_tables,
    pk_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, pk_tables
```
