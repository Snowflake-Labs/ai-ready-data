# Diagnostic: change_detection

Per-table breakdown of publication enrollment and audit trigger status.

## Context

Two diagnostic views are available:

1. **Publication status** — shows whether each table in the schema is enrolled in a logical replication publication. Tables not in any publication lack CDC coverage and require full-table scans to detect changes.
2. **Trigger inventory** — shows all non-internal triggers on tables in the schema, highlighting those with audit/tracking patterns. Useful for identifying trigger-based CDC mechanisms that operate outside the publication system.

## SQL

### Publication status

```sql
WITH all_tables AS (
    SELECT c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
published AS (
    SELECT DISTINCT tablename
    FROM pg_publication_tables
    WHERE schemaname = '{{ schema }}'
)
SELECT
    t.table_name,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT pt.pubname, ', ')
         FROM pg_publication_tables pt
         WHERE pt.schemaname = '{{ schema }}'
             AND pt.tablename = t.table_name),
        'none'
    ) AS publications,
    CASE
        WHEN p.tablename IS NOT NULL THEN 'IN_PUBLICATION'
        ELSE 'NOT_PUBLISHED'
    END AS status
FROM all_tables t
LEFT JOIN published p ON t.table_name = p.tablename
ORDER BY status DESC, t.table_name
```

### Trigger inventory

```sql
SELECT
    c.relname AS table_name,
    t.tgname AS trigger_name,
    CASE t.tgtype & 66
        WHEN 2 THEN 'BEFORE'
        WHEN 64 THEN 'INSTEAD OF'
        ELSE 'AFTER'
    END AS trigger_timing,
    CASE
        WHEN LOWER(t.tgname) LIKE '%audit%'
            OR LOWER(t.tgname) LIKE '%track%'
            OR LOWER(t.tgname) LIKE '%cdc%'
        THEN 'AUDIT/TRACKING'
        ELSE 'OTHER'
    END AS trigger_category
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
    AND c.relkind = 'r'
    AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname
```
