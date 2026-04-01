# Check: lineage_completeness

Fraction of tables with documented lineage via object dependency relationships.

## Context

Snowflake uses `ACCESS_HISTORY` to track query-level lineage (which queries read which tables). PostgreSQL has no equivalent query-level lineage tracking. Instead, this check uses `pg_depend` to identify tables that participate in documented transformation chains — i.e., tables that are referenced by views or materialized views.

A table with at least one downstream view or materialized view depending on it has "documented lineage" in the sense that its role in the data pipeline is codified in SQL definitions that PostgreSQL tracks automatically.

A score of 1.0 means every base table in the schema is referenced by at least one view or materialized view. Tables with no dependents may be standalone staging tables, or their lineage may exist outside PostgreSQL (in external ETL tools).

## SQL

```sql
WITH tables_in_scope AS (
    SELECT c.oid, c.relname
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
tables_with_dependents AS (
    SELECT DISTINCT t.relname
    FROM tables_in_scope t
    JOIN pg_depend d ON d.refobjid = t.oid
    JOIN pg_class dc ON dc.oid = d.objid
    WHERE dc.relkind IN ('v', 'm')
        AND d.deptype = 'n'
)
SELECT
    (SELECT COUNT(*) FROM tables_with_dependents) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_dependents)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
```
