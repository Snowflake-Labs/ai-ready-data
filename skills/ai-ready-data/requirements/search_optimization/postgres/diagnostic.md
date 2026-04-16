# Diagnostic: search_optimization

Per-table breakdown of search index status and searchable column inventory.

## Context

Lists every base table with its estimated row count, whether it has GIN or GiST indexes, and the count of columns with searchable data types (text, JSONB, arrays, tsvector). Tables with searchable columns but no GIN/GiST indexes are the primary candidates for remediation.

Tables without any searchable column types are shown for completeness but typically do not need search indexes.

## SQL

### Schema overview

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    COUNT(DISTINCT CASE
        WHEN pi.indexdef ILIKE '%USING gin%' OR pi.indexdef ILIKE '%USING gist%'
        THEN pi.indexname
    END) AS search_index_count,
    (
        SELECT COUNT(*)
        FROM information_schema.columns col
        WHERE col.table_schema = '{{ schema }}'
          AND col.table_name = c.relname
          AND col.data_type IN ('text', 'character varying', 'jsonb', 'json', 'ARRAY', 'tsvector', 'USER-DEFINED')
    ) AS searchable_columns,
    CASE
        WHEN COUNT(CASE
            WHEN pi.indexdef ILIKE '%USING gin%' OR pi.indexdef ILIKE '%USING gist%'
            THEN 1
        END) > 0 THEN 'HAS SEARCH INDEX'
        ELSE 'NO SEARCH INDEX'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_indexes pi
    ON pi.schemaname = n.nspname AND pi.tablename = c.relname
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
GROUP BY c.oid, c.relname, c.reltuples
ORDER BY status ASC, c.reltuples DESC
```

### Searchable columns without indexes (single table)

```sql
SELECT
    col.column_name,
    col.data_type,
    col.is_nullable,
    EXISTS (
        SELECT 1 FROM pg_indexes pi
        WHERE pi.schemaname = '{{ schema }}'
          AND pi.tablename = '{{ asset }}'
          AND (pi.indexdef ILIKE '%USING gin%' OR pi.indexdef ILIKE '%USING gist%')
          AND pi.indexdef ILIKE '%' || col.column_name || '%'
    ) AS has_search_index
FROM information_schema.columns col
WHERE col.table_schema = '{{ schema }}'
  AND col.table_name = '{{ asset }}'
  AND col.data_type IN ('text', 'character varying', 'jsonb', 'json', 'ARRAY', 'tsvector', 'USER-DEFINED')
ORDER BY col.ordinal_position
```
