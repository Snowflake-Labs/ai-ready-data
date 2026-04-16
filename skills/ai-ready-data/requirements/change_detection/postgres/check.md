# Check: change_detection

Fraction of tables with change data capture enabled.

## Context

Measures whether tables participate in PostgreSQL logical replication publications, which enable CDC (change data capture) workflows. Tables in publications have their INSERT, UPDATE, and DELETE events available to downstream consumers via logical replication slots.

Snowflake uses native change tracking and streams; PostgreSQL uses logical replication publications (`pg_publication_tables`). A table must be added to a publication for CDC consumers to receive its changes.

### Variant: Trigger-based audit

An alternative measure of change detection is trigger-based audit coverage — tables with triggers whose names suggest audit or change tracking (e.g., `%audit%`, `%track%`). This captures teams using trigger-based CDC patterns instead of logical replication.

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

### Trigger-based audit (variant)

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
audit_tables AS (
    SELECT COUNT(DISTINCT c.relname) AS cnt
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND (LOWER(t.tgname) LIKE '%audit%' OR LOWER(t.tgname) LIKE '%track%' OR LOWER(t.tgname) LIKE '%cdc%')
)
SELECT
    audit_tables.cnt AS tables_with_audit_triggers,
    table_count.cnt AS total_tables,
    audit_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, audit_tables
```
