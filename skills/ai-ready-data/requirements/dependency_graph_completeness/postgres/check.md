# Check: dependency_graph_completeness

Fraction of datasets with enumerated upstream or downstream dependency relationships.

## Context

Uses `pg_depend` to identify tables, views, and materialized views that participate in at least one dependency relationship — either as a source (referenced by another object) or as a consumer (referencing another object). This is the PostgreSQL equivalent of Snowflake's `object_dependencies` view.

PostgreSQL tracks structural dependencies automatically for views, materialized views, functions, and foreign key constraints. A score of 1.0 means every object in the schema has at least one tracked dependency relationship. Objects with no dependencies are typically standalone base tables with no views, foreign keys, or other SQL objects referencing them.

## SQL

```sql
WITH objects_in_scope AS (
    SELECT c.oid, c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind IN ('r', 'v', 'm')
),
has_upstream AS (
    SELECT DISTINCT o.relname AS table_name
    FROM objects_in_scope o
    JOIN pg_depend d ON d.objid = o.oid
    JOIN pg_class rc ON rc.oid = d.refobjid
    WHERE rc.relkind IN ('r', 'v', 'm')
        AND d.deptype = 'n'
        AND d.refobjid <> o.oid
),
has_downstream AS (
    SELECT DISTINCT o.relname AS table_name
    FROM objects_in_scope o
    JOIN pg_depend d ON d.refobjid = o.oid
    JOIN pg_class dc ON dc.oid = d.objid
    WHERE dc.relkind IN ('r', 'v', 'm')
        AND d.deptype = 'n'
        AND d.objid <> o.oid
),
objects_with_deps AS (
    SELECT table_name FROM has_upstream
    UNION
    SELECT table_name FROM has_downstream
)
SELECT
    (SELECT COUNT(*) FROM objects_with_deps) AS objects_with_dependencies,
    (SELECT COUNT(*) FROM objects_in_scope) AS total_objects,
    (SELECT COUNT(*) FROM objects_with_deps)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM objects_in_scope)::NUMERIC, 0) AS value
```
