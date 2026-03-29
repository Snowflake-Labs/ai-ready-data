# Check: dependency_graph_completeness

Fraction of datasets with fully enumerated upstream and downstream dependency relationships.

## Context

Uses `snowflake.account_usage.object_dependencies` to identify tables, views, and dynamic tables that appear as either a referencing or referenced object. Scoped to a single schema.

A score of 1.0 means every object in the schema participates in at least one documented dependency relationship. Objects with no dependency records may be standalone tables with no views or downstream consumers, or they may lack dependency tracking because they were loaded via external tooling that bypasses Snowflake lineage capture.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('BASE TABLE', 'VIEW', 'DYNAMIC TABLE')
),
tables_with_dependencies AS (
    SELECT DISTINCT referencing_object_name AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referencing_database) = UPPER('{{ database }}')
        AND UPPER(referencing_schema) = UPPER('{{ schema }}')
    UNION
    SELECT DISTINCT referenced_object_name AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referenced_database) = UPPER('{{ database }}')
        AND UPPER(referenced_schema) = UPPER('{{ schema }}')
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t 
     WHERE t.table_name IN (SELECT table_name FROM tables_with_dependencies)
    ) AS tables_with_dependencies,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_in_scope t 
     WHERE t.table_name IN (SELECT table_name FROM tables_with_dependencies)
    )::FLOAT / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```
