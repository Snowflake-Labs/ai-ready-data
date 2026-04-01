# Diagnostic: lineage_completeness

Per-table breakdown of lineage documentation via downstream dependencies.

## Context

Shows each base table alongside its downstream dependents (views and materialized views) as tracked in `pg_depend`. Tables with `HAS_LINEAGE` are referenced by at least one view or materialized view, establishing a structural lineage chain. Tables with `NO_LINEAGE` have no tracked downstream SQL objects.

Snowflake's `ACCESS_HISTORY` captures query-level lineage automatically; PostgreSQL only tracks structural dependencies via `pg_depend`. Tables consumed by external tools (BI dashboards, application queries, ETL pipelines) will show as `NO_LINEAGE` even if they are actively used.

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
        t.table_name,
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
        AND d.objid <> t.oid
),
dep_summary AS (
    SELECT
        table_name,
        COUNT(DISTINCT dependent_name) AS dependent_count,
        STRING_AGG(DISTINCT dependent_type || ':' || dependent_name, ', '
                   ORDER BY dependent_type || ':' || dependent_name) AS dependent_objects
    FROM dependents
    GROUP BY table_name
)
SELECT
    t.table_name,
    pg_relation_size(t.oid) / (1024 * 1024) AS size_mb,
    COALESCE(ds.dependent_count, 0) AS downstream_dependents,
    COALESCE(ds.dependent_objects, 'none') AS dependent_objects,
    CASE
        WHEN ds.table_name IS NOT NULL THEN 'HAS_LINEAGE'
        ELSE 'NO_LINEAGE'
    END AS lineage_status
FROM all_tables t
LEFT JOIN dep_summary ds ON t.table_name = ds.table_name
ORDER BY downstream_dependents DESC, t.table_name
```
