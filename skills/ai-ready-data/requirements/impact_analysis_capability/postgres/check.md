# Check: impact_analysis_capability

Fraction of datasets where downstream impact of a schema or content change can be automatically enumerated.

## Context

Uses `pg_depend` to count how many base tables in the schema have at least one downstream dependent — a view, materialized view, or other object that references the table. Tables with downstream dependents enable automatic impact analysis: before changing a column or dropping a table, the dependency chain reveals what will break.

Snowflake uses `object_dependencies` with ~2 hour latency; PostgreSQL's `pg_depend` is updated immediately. However, `pg_depend` only tracks structural SQL dependencies — external consumers (BI tools, ETL pipelines, application queries) are not visible.

A score of 1.0 means every base table has at least one tracked downstream dependent.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
tables_with_downstream AS (
    SELECT COUNT(DISTINCT c.relname) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_depend d ON d.refobjid = c.oid
    JOIN pg_class dc ON dc.oid = d.objid
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND dc.relkind IN ('v', 'm')
        AND d.deptype = 'n'
        AND d.objid <> c.oid
)
SELECT
    tables_with_downstream.cnt AS tables_with_dependents,
    table_count.cnt AS total_tables,
    tables_with_downstream.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, tables_with_downstream
```
