# Check: lineage_completeness

Fraction of tables with documented lineage via downstream object dependencies.

## Context

Snowflake uses `ACCESS_HISTORY` to track query-level lineage (which queries read which tables). PostgreSQL has no equivalent query-level lineage tracking. Instead, this check uses `pg_depend` to identify tables that appear as sources for views or materialized views — indicating they participate in a documented transformation chain.

A table with at least one downstream dependent (view or materialized view) has structural lineage: its role as a source in a transformation is encoded in the SQL definition of the dependent object. Tables without dependents may still be consumed by external tools, but that lineage is not tracked by PostgreSQL.

A score of 1.0 means every base table is referenced by at least one view or materialized view.

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
        AND d.objid <> t.oid
)
SELECT
    (SELECT COUNT(*) FROM tables_with_dependents) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_dependents)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
```
