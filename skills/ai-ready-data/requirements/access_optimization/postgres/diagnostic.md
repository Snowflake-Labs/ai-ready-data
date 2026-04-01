# Diagnostic: access_optimization

Per-table breakdown of index status across the schema.

## Context

Lists every base table with its estimated row count, table size, number of indexes, and a status label: `SMALL (OK)` for tables under 10,000 rows, `INDEXED` for large tables with at least one index, and `NEEDS INDEX` for large tables without any indexes.

Tables marked `NEEDS INDEX` are candidates for the fix. Tables marked `SMALL (OK)` are excluded from the check score entirely.

Row estimates come from `pg_class.reltuples` (updated by `ANALYZE`). Table sizes are computed via `pg_total_relation_size`, which includes indexes and TOAST data.

### Index details (per-table deep dive)

For tables that already have indexes, you can assess usage and effectiveness with the index-usage query below. A low `idx_scan` count relative to `seq_scan` suggests the existing indexes are not being used by the query planner.

## SQL

### Schema overview

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    (SELECT COUNT(*) FROM pg_index i WHERE i.indrelid = c.oid) AS index_count,
    CASE
        WHEN c.reltuples <= 10000 THEN 'SMALL (OK)'
        WHEN EXISTS (SELECT 1 FROM pg_index i WHERE i.indrelid = c.oid) THEN 'INDEXED'
        ELSE 'NEEDS INDEX'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY c.reltuples DESC
```

### Index usage (per-table, requires pg_stat_user_indexes)

```sql
SELECT
    s.relname AS table_name,
    s.indexrelname AS index_name,
    s.idx_scan,
    s.idx_tup_read,
    s.idx_tup_fetch,
    pg_size_pretty(pg_relation_size(s.indexrelid)) AS index_size
FROM pg_stat_user_indexes s
JOIN pg_namespace n ON n.oid = (
    SELECT relnamespace FROM pg_class WHERE oid = s.relid
)
WHERE n.nspname = '{{ schema }}'
  AND s.relname = '{{ asset }}'
ORDER BY s.idx_scan DESC
```
