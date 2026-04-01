# Diagnostic: lineage_completeness

Per-table breakdown of downstream dependency relationships indicating documented lineage.

## Context

Lists every base table in the schema alongside its downstream dependents (views and materialized views) as tracked by `pg_depend`. Tables with `HAS_LINEAGE` have at least one view or materialized view that references them; `NO_LINEAGE` indicates no downstream SQL objects depend on the table.

Unlike Snowflake's `ACCESS_HISTORY`, which captures query-level lineage automatically, PostgreSQL only tracks structural dependencies — relationships defined in view/matview SQL definitions. External ETL pipelines that read from tables without creating views will not appear here.

## SQL

```sql
WITH all_tables AS (
    SELECT c.oid, c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
dependents AS (
    SELECT
        t.table_name AS source_table,
        dc.relname AS dependent_name,
        CASE dc.relkind
            WHEN 'v' THEN 'VIEW'
            WHEN 'm' THEN 'MATERIALIZED VIEW'
        END AS dependent_type
    FROM all_tables t
    JOIN pg_depend d ON d.refobjid = t.oid
    JOIN pg_class dc ON dc.oid = d.objid
    WHERE dc.relkind IN ('v', 'm')
        AND d.deptype = 'n'
),
dep_summary AS (
    SELECT
        source_table,
        COUNT(DISTINCT dependent_name) AS dependent_count,
        STRING_AGG(DISTINCT dependent_type || ':' || dependent_name, ', '
                   ORDER BY dependent_type || ':' || dependent_name) AS dependent_objects
    FROM dependents
    GROUP BY source_table
)
SELECT
    t.table_name,
    COALESCE(ds.dependent_count, 0) AS downstream_dependents,
    COALESCE(ds.dependent_objects, 'none') AS dependent_objects,
    CASE
        WHEN ds.source_table IS NOT NULL THEN 'HAS_LINEAGE'
        ELSE 'NO_LINEAGE'
    END AS status
FROM all_tables t
LEFT JOIN dep_summary ds ON t.table_name = ds.source_table
ORDER BY status DESC, t.table_name
```
