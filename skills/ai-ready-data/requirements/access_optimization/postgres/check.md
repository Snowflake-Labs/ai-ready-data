# Check: access_optimization

Fraction of tables in the schema that have at least one B-tree or BRIN index.

## Context

Queries `pg_class` and `pg_indexes` to compare the number of tables with at least one index against the total number of base tables in the schema. Returns a ratio between 0.0 (no tables indexed) and 1.0 (all tables indexed).

Unlike Snowflake's clustering keys, PostgreSQL indexes are explicit objects that must be created and maintained by the user. B-tree indexes are the most common and cover equality and range predicates; BRIN indexes are effective for large, naturally ordered tables (e.g., append-only time-series).

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
indexed_tables AS (
    SELECT COUNT(DISTINCT tablename) AS cnt
    FROM pg_indexes
    WHERE schemaname = '{{ schema }}'
)
SELECT
    indexed_tables.cnt AS tables_with_indexes,
    table_count.cnt AS total_tables,
    indexed_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, indexed_tables
```
