# Check: search_optimization

Fraction of tables in the schema with GIN or GiST search indexes.

## Context

In PostgreSQL, search optimization is achieved through GIN indexes (for full-text search, JSONB, and array columns) and GiST indexes (for geometric, range, and full-text data). This check counts the fraction of tables that have at least one GIN or GiST index.

Unlike Snowflake's built-in search optimization toggle, PostgreSQL requires explicit index creation on the columns you want to optimize. Not every table needs a search index — only those queried with full-text search (`@@`), JSONB operators (`@>`, `?`, `?|`), or array containment (`@>`).

The check inspects `pg_indexes.indexdef` to detect GIN and GiST access methods.

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
    table_count.cnt      AS total_tables,
    search_optimized.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, search_optimized
```
