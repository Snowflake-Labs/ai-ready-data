# Diagnostic: impact_analysis_capability

Per-table breakdown of downstream impact chain for all base tables in the schema.

## Context

Lists every base table alongside its downstream dependents (views and materialized views that reference it via `pg_depend`). Tables with `NO_DEPENDENTS_TRACKED` have no recorded downstream objects — schema changes to these tables cannot be impact-assessed automatically via the PostgreSQL catalog.

Includes approximate row count and the list of dependent objects to help prioritize which tables need downstream documentation.

## SQL

```sql
WITH all_tables AS (
    SELECT c.oid, c.relname AS table_name,
        (SELECT reltuples::BIGINT FROM pg_class WHERE oid = c.oid) AS approx_row_count
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
      AND d.objid <> d.refobjid
),
agg_dependents AS (
    SELECT
        table_name,
        COUNT(*) AS downstream_count,
        STRING_AGG(dependent_type || ':' || dependent_name, ', ' ORDER BY dependent_name) AS dependent_objects
    FROM dependents
    GROUP BY table_name
)
SELECT
    t.table_name,
    t.approx_row_count,
    COALESCE(a.downstream_count, 0) AS downstream_dependents,
    COALESCE(a.dependent_objects, 'none') AS dependent_objects,
    CASE
        WHEN a.downstream_count > 0 THEN 'HAS_DEPENDENTS'
        ELSE 'NO_DEPENDENTS_TRACKED'
    END AS status
FROM all_tables t
LEFT JOIN agg_dependents a ON t.table_name = a.table_name
ORDER BY downstream_dependents DESC, t.table_name;
```
