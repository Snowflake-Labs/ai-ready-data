# Diagnostic: dependency_graph_completeness

Per-object breakdown of dependency graph participation for all tables, views, and materialized views in the schema.

## Context

Lists every object in scope alongside its upstream and downstream dependency status as tracked by `pg_depend`. Objects with `HAS_DEPENDENCIES` participate in at least one structural dependency relationship; `NO_DEPENDENCIES` objects are isolated — they neither reference nor are referenced by other objects in the schema.

Unlike Snowflake's `object_dependencies` (which has ~2 hour latency), PostgreSQL's `pg_depend` is updated immediately when objects are created or dropped.

## SQL

```sql
WITH objects_in_scope AS (
    SELECT c.oid, c.relname AS table_name,
        CASE c.relkind
            WHEN 'r' THEN 'BASE TABLE'
            WHEN 'v' THEN 'VIEW'
            WHEN 'm' THEN 'MATERIALIZED VIEW'
        END AS object_type
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind IN ('r', 'v', 'm')
),
upstream AS (
    SELECT DISTINCT o.table_name
    FROM objects_in_scope o
    JOIN pg_depend d ON d.objid = o.oid
    JOIN pg_class rc ON rc.oid = d.refobjid
    WHERE rc.relkind IN ('r', 'v', 'm')
        AND d.deptype = 'n'
        AND d.refobjid <> o.oid
),
downstream AS (
    SELECT DISTINCT o.table_name
    FROM objects_in_scope o
    JOIN pg_depend d ON d.refobjid = o.oid
    JOIN pg_class dc ON dc.oid = d.objid
    WHERE dc.relkind IN ('r', 'v', 'm')
        AND d.deptype = 'n'
        AND d.objid <> o.oid
)
SELECT
    o.table_name,
    o.object_type,
    CASE WHEN u.table_name IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_upstream,
    CASE WHEN d.table_name IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_downstream,
    CASE
        WHEN u.table_name IS NOT NULL OR d.table_name IS NOT NULL THEN 'HAS_DEPENDENCIES'
        ELSE 'NO_DEPENDENCIES'
    END AS status
FROM objects_in_scope o
LEFT JOIN upstream u ON o.table_name = u.table_name
LEFT JOIN downstream d ON o.table_name = d.table_name
ORDER BY status DESC, o.table_name
```
