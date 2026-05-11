# Diagnostic: access_optimization

Per-table breakdown of index status across the schema.

## Context

Lists every base table with its estimated row count, size, index count, and index names. Tables are classified as `INDEXED` or `NEEDS INDEX` based on whether they have at least one index. Results are ordered by estimated row count descending so the largest unindexed tables surface first.

The row estimate comes from `pg_class.reltuples`, which is updated by `ANALYZE`. If the table has never been analyzed, the estimate may be stale or zero.

### Index detail (per-table deep dive)

For tables that already have indexes, the per-table query shows each index's definition, size, and scan count from `pg_stat_user_indexes`. A high `idx_scan` count confirms the index is being used; zero scans may indicate a dead index candidate for removal.

## SQL

### Schema overview

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    COUNT(i.indexname) AS index_count,
    STRING_AGG(i.indexname, ', ' ORDER BY i.indexname) AS index_names,
    CASE
        WHEN COUNT(i.indexname) > 0 THEN 'INDEXED'
        ELSE 'NEEDS INDEX'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_indexes i
    ON i.schemaname = n.nspname AND i.tablename = c.relname
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
GROUP BY c.oid, c.relname, c.reltuples
ORDER BY c.reltuples DESC
```

### Index detail (single table)

```sql
SELECT
    i.indexname,
    i.indexdef,
    pg_size_pretty(pg_relation_size(ix.indexrelid)) AS index_size,
    s.idx_scan,
    s.idx_tup_read,
    s.idx_tup_fetch
FROM pg_indexes i
JOIN pg_stat_user_indexes s
    ON s.indexrelname = i.indexname AND s.schemaname = i.schemaname
JOIN pg_index ix
    ON ix.indexrelid = s.indexrelid
WHERE i.schemaname = '{{ schema }}'
  AND i.tablename = '{{ asset }}'
ORDER BY s.idx_scan DESC
```
