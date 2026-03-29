# Diagnostic: dependency_graph_completeness

Per-object breakdown of dependency graph participation for all tables, views, and dynamic tables in the schema.

## Context

Lists every object in scope alongside the count of upstream (referenced) and downstream (referencing) dependencies recorded in `snowflake.account_usage.object_dependencies`. Objects with zero dependencies in both directions are flagged as `NO_DEPENDENCIES`.

`object_dependencies` has approximately 2-hour latency — recently created objects or newly established references may not appear yet. Requires IMPORTED PRIVILEGES on the SNOWFLAKE database.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT table_name, table_type
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('BASE TABLE', 'VIEW', 'DYNAMIC TABLE')
),
upstream AS (
    SELECT DISTINCT referencing_object_name AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referencing_database) = UPPER('{{ database }}')
        AND UPPER(referencing_schema) = UPPER('{{ schema }}')
),
downstream AS (
    SELECT DISTINCT referenced_object_name AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referenced_database) = UPPER('{{ database }}')
        AND UPPER(referenced_schema) = UPPER('{{ schema }}')
)
SELECT
    t.table_name,
    t.table_type,
    CASE WHEN u.table_name IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_upstream,
    CASE WHEN d.table_name IS NOT NULL THEN 'YES' ELSE 'NO' END AS has_downstream,
    CASE
        WHEN u.table_name IS NOT NULL OR d.table_name IS NOT NULL THEN 'HAS_DEPENDENCIES'
        ELSE 'NO_DEPENDENCIES'
    END AS status
FROM tables_in_scope t
LEFT JOIN upstream u ON UPPER(t.table_name) = UPPER(u.table_name)
LEFT JOIN downstream d ON UPPER(t.table_name) = UPPER(d.table_name)
ORDER BY status DESC, t.table_name
```
