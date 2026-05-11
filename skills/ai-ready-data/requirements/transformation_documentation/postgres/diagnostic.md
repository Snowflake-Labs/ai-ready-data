# Diagnostic: transformation_documentation

Per-object breakdown of documentation status for views, materialized views, and functions.

## Context

Shows each transformation object with its documentation status: `DOCUMENTED` (comment >20 chars), `PARTIAL` (comment exists but too short), or `UNDOCUMENTED` (no comment). Includes the object type, whether it has a stored definition, and a recommendation.

Views and materialized views have self-documenting SQL definitions accessible via `pg_views` / `pg_matviews`, but comments explaining business intent are still valuable and required for the check to pass.

## SQL

```sql
WITH transformations AS (
    SELECT
        c.oid,
        c.relname AS object_name,
        CASE c.relkind
            WHEN 'v' THEN 'VIEW'
            WHEN 'm' THEN 'MATERIALIZED VIEW'
        END AS object_type,
        TRUE AS has_definition
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind IN ('v', 'm')

    UNION ALL

    SELECT
        p.oid,
        p.proname AS object_name,
        CASE p.prokind
            WHEN 'f' THEN 'FUNCTION'
            WHEN 'p' THEN 'PROCEDURE'
        END AS object_type,
        (p.prosrc IS NOT NULL AND p.prosrc != '') AS has_definition
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = '{{ schema }}'
      AND p.prokind IN ('f', 'p')
)
SELECT
    t.object_name,
    t.object_type,
    t.has_definition,
    CASE
        WHEN obj_description(t.oid) IS NOT NULL AND LENGTH(obj_description(t.oid)) > 20 THEN 'DOCUMENTED'
        WHEN obj_description(t.oid) IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    COALESCE(obj_description(t.oid), '') AS current_comment,
    CASE
        WHEN obj_description(t.oid) IS NOT NULL AND LENGTH(obj_description(t.oid)) > 20 THEN 'Transformation documented'
        ELSE 'Add COMMENT explaining transformation logic, inputs, and outputs'
    END AS recommendation
FROM transformations t
ORDER BY documentation_status DESC, t.object_name
```
