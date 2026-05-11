# Diagnostic: change_detection

Per-table breakdown of publication membership and audit trigger status.

## Context

Two diagnostic views are available:

1. **Publication membership** — shows whether each table is included in a logical replication publication. Tables not in any publication cannot emit CDC events to downstream consumers.
2. **Trigger inventory** — shows all triggers in the schema that suggest audit or change tracking behavior. Useful for teams using trigger-based CDC instead of logical replication.

## SQL

### Publication membership

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
    CASE
        WHEN p.tablename IS NOT NULL THEN 'IN_PUBLICATION'
        ELSE 'NOT_PUBLISHED'
    END AS status,
    p.tablename IS NOT NULL AS in_publication
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
    END AS timing,
    CASE
        WHEN t.tgtype & 4 > 0 THEN 'INSERT'
        WHEN t.tgtype & 8 > 0 THEN 'DELETE'
        WHEN t.tgtype & 16 > 0 THEN 'UPDATE'
    END AS event
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
    AND c.relkind = 'r'
    AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname
```
