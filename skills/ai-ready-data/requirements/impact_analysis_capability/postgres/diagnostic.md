# Diagnostic: impact_analysis_capability

Per-table breakdown of downstream dependents for impact analysis coverage.

## Context

Lists every base table in the schema with its downstream dependent count and the names of dependent objects (views, materialized views). Tables with `HAS_DEPENDENTS` can be impact-analyzed before schema changes; tables with `NO_DEPENDENTS_TRACKED` have no downstream SQL objects and their change impact cannot be automatically enumerated.

PostgreSQL's `pg_depend` tracks only structural SQL dependencies. External consumers (application queries, BI dashboards, ETL jobs) are not visible — document those with comments for complete impact coverage.

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
        COUNT(DISTINCT dependent_name) AS downstream_count,
        STRING_AGG(DISTINCT dependent_type || ':' || dependent_name, ', '
                   ORDER BY dependent_type || ':' || dependent_name) AS dependent_objects
    FROM dependents
    GROUP BY table_name
)
SELECT
    t.table_name,
    pg_relation_size(t.oid) / (1024 * 1024) AS size_mb,
    COALESCE(ds.downstream_count, 0) AS downstream_dependents,
    COALESCE(ds.dependent_objects, 'none') AS dependent_objects,
    CASE
        WHEN ds.table_name IS NOT NULL THEN 'HAS_DEPENDENTS'
        ELSE 'NO_DEPENDENTS_TRACKED'
    END AS status
FROM all_tables t
LEFT JOIN dep_summary ds ON t.table_name = ds.table_name
ORDER BY downstream_dependents DESC, t.table_name
```
