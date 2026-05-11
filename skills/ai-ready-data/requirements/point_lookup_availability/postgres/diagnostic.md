# Diagnostic: point_lookup_availability

Per-table breakdown of primary key and unique index status.

## Context

Lists every base table with its estimated row count, primary key columns (if any), unique index count, and a lookup capability classification. Tables are classified as:

- `HAS PK` — Has a primary key (best for point lookups)
- `UNIQUE ONLY` — Has a unique index but no primary key (still enables efficient point lookups, but PK is preferred for semantic clarity)
- `NO KEY` — No primary key or unique index (point lookups require sequential scans)

Tables marked `NO KEY` are the primary candidates for remediation.

## SQL

### Schema overview

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    (
        SELECT STRING_AGG(a.attname, ', ' ORDER BY array_position(ix.indkey, a.attnum))
        FROM pg_index ix
        JOIN pg_attribute a ON a.attrelid = ix.indrelid AND a.attnum = ANY(ix.indkey)
        WHERE ix.indrelid = c.oid AND ix.indisprimary
    ) AS pk_columns,
    (
        SELECT COUNT(*)
        FROM pg_index ix
        WHERE ix.indrelid = c.oid AND ix.indisunique AND NOT ix.indisprimary
    ) AS unique_index_count,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisprimary)
            THEN 'HAS PK'
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisunique)
            THEN 'UNIQUE ONLY'
        ELSE 'NO KEY'
    END AS lookup_capability,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisprimary)
            THEN 'Ready for point lookups'
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisunique)
            THEN 'Add primary key for semantic clarity'
        ELSE 'Add primary key on lookup columns'
    END AS recommendation
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY lookup_capability DESC, c.reltuples DESC
```

### Column candidates for primary key (single table without PK)

```sql
SELECT
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    NOT a.attnotnull AS is_nullable,
    (
        SELECT COUNT(DISTINCT t.val)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0)
        FROM (SELECT {{ column }} AS val FROM {{ schema }}.{{ asset }} TABLESAMPLE BERNOULLI(1)) t
    ) AS estimated_uniqueness
FROM pg_attribute a
WHERE a.attrelid = '{{ schema }}.{{ asset }}'::regclass
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY a.attnum
```
