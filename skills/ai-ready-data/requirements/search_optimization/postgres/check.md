# Check: search_optimization

Fraction of tables with GIN or GiST indexes for search optimization.

## Context

In Snowflake, search optimization is a built-in table-level property. In PostgreSQL, the equivalent capability comes from GIN and GiST indexes:

- **GIN** (Generalized Inverted Index) — Accelerates full-text search (`tsvector`), JSONB containment (`@>`), array overlap (`&&`), and trigram similarity (`%`).
- **GiST** (Generalized Search Tree) — Accelerates geometric types, range types, full-text search, and nearest-neighbor queries.

This check counts tables that have at least one GIN or GiST index, indicating search optimization is in place. Tables without searchable column types (text, JSONB, arrays, ranges) may not need these indexes.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
search_optimized AS (
    SELECT COUNT(DISTINCT tablename) AS cnt
    FROM pg_indexes
    WHERE schemaname = '{{ schema }}'
      AND (indexdef ILIKE '%USING gin%' OR indexdef ILIKE '%USING gist%')
)
SELECT
    search_optimized.cnt AS tables_with_search_indexes,
    table_count.cnt AS total_tables,
    search_optimized.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, search_optimized
```
