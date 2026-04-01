# Check: access_optimization

Fraction of large tables in the schema that have at least one B-tree or BRIN index.

## Context

Only tables with more than 10,000 estimated rows are evaluated — small tables don't benefit from indexing and would inflate the score. Row estimates come from `pg_class.reltuples`, which is updated by `ANALYZE`. If the schema has no tables above this threshold, the check returns NULL (division by zero guard), which should be treated as not applicable.

An index being *present* does not mean it is *effective*. Use the diagnostic to assess index usage and bloat on individual tables.

## SQL

```sql
WITH large_tables AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND c.reltuples > 10000
),
indexed AS (
    SELECT COUNT(DISTINCT c.oid) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_index i ON i.indrelid = c.oid
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND c.reltuples > 10000
)
SELECT
    indexed.cnt   AS tables_with_indexes,
    large_tables.cnt AS large_tables,
    indexed.cnt::NUMERIC / NULLIF(large_tables.cnt::NUMERIC, 0) AS value
FROM large_tables, indexed
```
