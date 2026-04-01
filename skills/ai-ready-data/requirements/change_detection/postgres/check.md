# Check: change_detection

Fraction of tables with change-data-capture mechanisms enabled.

## Context

Measures whether tables participate in PostgreSQL logical replication publications, which provide CDC (change data capture) capabilities analogous to Snowflake's change tracking and streams. Tables in a publication emit row-level changes that downstream consumers (logical replication subscribers, Debezium, etc.) can process incrementally.

The primary check queries `pg_publication_tables` to find tables enrolled in any publication. The variant check looks for trigger-based audit patterns — tables with triggers whose names suggest audit or change tracking (`%audit%`, `%track%`, `%cdc%`).

A score of 1.0 means every base table in the schema is covered by at least one CDC mechanism.

## SQL

### Publication coverage (primary)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
published_tables AS (
    SELECT COUNT(DISTINCT tablename) AS cnt
    FROM pg_publication_tables
    WHERE schemaname = '{{ schema }}'
)
SELECT
    published_tables.cnt AS tables_with_cdc,
    table_count.cnt AS total_tables,
    published_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, published_tables
```

### Trigger-based audit coverage (variant)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
tables_with_audit_triggers AS (
    SELECT COUNT(DISTINCT c.relname) AS cnt
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND NOT t.tgisinternal
        AND (LOWER(t.tgname) LIKE '%audit%'
             OR LOWER(t.tgname) LIKE '%track%'
             OR LOWER(t.tgname) LIKE '%cdc%')
)
SELECT
    tables_with_audit_triggers.cnt AS tables_with_cdc,
    table_count.cnt AS total_tables,
    tables_with_audit_triggers.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, tables_with_audit_triggers
```
