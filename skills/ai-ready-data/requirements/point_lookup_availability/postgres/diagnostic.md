# Diagnostic: point_lookup_availability

Per-table breakdown of point-lookup readiness across the schema.

## Context

Lists every base table with its estimated row count, primary key (if any), unique indexes, and a lookup capability classification:

- `HAS PK` — Table has a primary key (best for point lookups).
- `UNIQUE INDEX ONLY` — Table has a unique index but no declared primary key. Functionally equivalent for lookups, but a PK is preferred for semantic clarity.
- `NO UNIQUE KEY` — Table has no primary key or unique index. Point lookups require sequential scans.

Tables marked `NO UNIQUE KEY` are candidates for the fix. The second query shows column details for a specific table to help identify natural key candidates.

## SQL

### Schema overview

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    (
        SELECT string_agg(a.attname, ', ' ORDER BY array_position(ix.indkey, a.attnum))
        FROM pg_index ix
        JOIN pg_attribute a ON a.attrelid = ix.indrelid AND a.attnum = ANY(ix.indkey)
        WHERE ix.indrelid = c.oid AND ix.indisprimary
    ) AS primary_key_columns,
    (
        SELECT COUNT(*)
        FROM pg_index ix
        WHERE ix.indrelid = c.oid AND ix.indisunique AND NOT ix.indisprimary
    ) AS unique_index_count,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisprimary)
            THEN 'HAS PK'
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisunique)
            THEN 'UNIQUE INDEX ONLY'
        ELSE 'NO UNIQUE KEY'
    END AS lookup_capability,
    CASE
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisprimary)
            THEN 'Ready for point lookups'
        WHEN EXISTS (SELECT 1 FROM pg_index ix WHERE ix.indrelid = c.oid AND ix.indisunique)
            THEN 'Consider adding a primary key for semantic clarity'
        ELSE 'Add primary key or unique index on lookup columns'
    END AS recommendation
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY lookup_capability DESC, c.reltuples DESC
```

### Column details (single table, for identifying key candidates)

```sql
SELECT
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    NOT a.attnotnull AS is_nullable,
    (
        SELECT COUNT(DISTINCT t.val)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0)
        FROM (SELECT ({{ column_expr }})::TEXT AS val FROM {{ schema }}.{{ asset }} TABLESAMPLE BERNOULLI(1)) t
    ) AS estimated_uniqueness
FROM pg_attribute a
WHERE a.attrelid = '{{ schema }}.{{ asset }}'::regclass
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY a.attnum
```
