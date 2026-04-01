# Diagnostic: search_optimization

Per-table breakdown of search index status across the schema.

## Context

Lists every base table in the schema with its estimated row count, total size, existing GIN/GiST indexes (if any), and a status label: `HAS SEARCH INDEX` for tables with at least one GIN or GiST index, and `NO SEARCH INDEX` for those without.

Tables marked `NO SEARCH INDEX` are not necessarily problems — only tables with text, JSONB, array, or geometric columns that are queried with search operators benefit from these indexes. The second query identifies columns that are candidates for search optimization.

## SQL

### Schema overview

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    (
        SELECT string_agg(indexname, ', ')
        FROM pg_indexes pi
        WHERE pi.schemaname = '{{ schema }}'
          AND pi.tablename = c.relname
          AND (pi.indexdef ILIKE '%USING gin%' OR pi.indexdef ILIKE '%USING gist%')
    ) AS search_indexes,
    CASE
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes pi
            WHERE pi.schemaname = '{{ schema }}'
              AND pi.tablename = c.relname
              AND (pi.indexdef ILIKE '%USING gin%' OR pi.indexdef ILIKE '%USING gist%')
        ) THEN 'HAS SEARCH INDEX'
        ELSE 'NO SEARCH INDEX'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY status, c.reltuples DESC
```

### Candidate columns for search indexes

```sql
SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    CASE
        WHEN c.data_type IN ('text', 'character varying', 'char') THEN 'GIN (tsvector)'
        WHEN c.data_type = 'jsonb' THEN 'GIN (jsonb_ops)'
        WHEN c.data_type = 'ARRAY' THEN 'GIN (array_ops)'
        WHEN c.udt_name IN ('tsvector') THEN 'GIN (tsvector_ops)'
        WHEN c.data_type = 'json' THEN 'Cast to JSONB first, then GIN'
        ELSE 'GiST (if range/geometric)'
    END AS recommended_index
FROM information_schema.columns c
JOIN information_schema.tables t
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE c.table_schema = '{{ schema }}'
  AND t.table_type = 'BASE TABLE'
  AND (
      c.data_type IN ('text', 'character varying', 'jsonb', 'json', 'ARRAY')
      OR c.udt_name IN ('tsvector', 'tsquery')
  )
ORDER BY c.table_name, c.ordinal_position
```
