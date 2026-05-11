# Diagnostic: retention_policy

Per-table breakdown of retention policy coverage.

## Context

Shows each base table and partitioned table with its estimated row count, partitioning strategy (if any), comment-based retention status, and an overall retention classification. Tables with `NO_RETENTION_POLICY` have neither a retention-keyword comment nor range partitioning indicating lifecycle management.

PostgreSQL does not have Snowflake's Time Travel retention setting. Instead, this diagnostic checks for range partitioning (common for time-based lifecycle management) and structured retention comments.

## SQL

```sql
SELECT
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    CASE c.relkind
        WHEN 'p' THEN 'PARTITIONED'
        ELSE 'REGULAR'
    END AS table_type,
    CASE
        WHEN pt.partstrat = 'r' THEN 'RANGE'
        WHEN pt.partstrat = 'l' THEN 'LIST'
        WHEN pt.partstrat = 'h' THEN 'HASH'
        ELSE NULL
    END AS partition_strategy,
    COALESCE(obj_description(c.oid), '') AS current_comment,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL AND (
            LOWER(obj_description(c.oid)) LIKE '%retention%'
            OR LOWER(obj_description(c.oid)) LIKE '%ttl%'
            OR LOWER(obj_description(c.oid)) LIKE '%expire%'
            OR LOWER(obj_description(c.oid)) LIKE '%purge%'
            OR LOWER(obj_description(c.oid)) LIKE '%archive%'
            OR LOWER(obj_description(c.oid)) LIKE '%lifecycle%'
        ) THEN 'HAS_RETENTION_COMMENT'
        WHEN c.relkind = 'p' AND pt.partstrat = 'r' THEN 'HAS_RANGE_PARTITIONING'
        ELSE 'NO_RETENTION_POLICY'
    END AS status,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL AND (
            LOWER(obj_description(c.oid)) LIKE '%retention%'
            OR LOWER(obj_description(c.oid)) LIKE '%ttl%'
        ) THEN 'Retention policy documented in comment'
        WHEN c.relkind = 'p' AND pt.partstrat = 'r' THEN 'Range partitioning indicates lifecycle management'
        ELSE 'Add retention COMMENT or set up range partitioning for lifecycle management'
    END AS recommendation
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_partitioned_table pt ON pt.partrelid = c.oid
WHERE n.nspname = '{{ schema }}'
  AND c.relkind IN ('r', 'p')
ORDER BY status DESC, c.relname
```
