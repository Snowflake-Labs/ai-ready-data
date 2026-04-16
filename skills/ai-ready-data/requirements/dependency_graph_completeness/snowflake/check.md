# Check: dependency_graph_completeness

Fraction of tables, views, and dynamic tables in the schema that participate in at least one documented dependency relationship.

## Context

Uses `snowflake.account_usage.object_dependencies` to identify objects that appear on either side of a dependency edge (as the referencing or the referenced object). A score of 1.0 means every object in the schema has at least one documented relationship.

Objects with no dependency records may be standalone (no consumers and no upstream references), or they may bypass Snowflake lineage capture — e.g. external ELT tools that materialize tables via direct inserts.

`account_usage.object_dependencies` has approximately 2-hour latency.

Returns NULL (N/A) when the schema contains no in-scope objects.

## SQL

```sql
WITH objects_in_scope AS (
    SELECT DISTINCT UPPER(table_name) AS object_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type IN ('BASE TABLE','VIEW','DYNAMIC TABLE')
),
objects_with_dependencies AS (
    SELECT DISTINCT UPPER(referencing_object_name) AS object_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referencing_database) = UPPER('{{ database }}')
        AND UPPER(referencing_schema)   = UPPER('{{ schema }}')
    UNION
    SELECT DISTINCT UPPER(referenced_object_name) AS object_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referenced_database) = UPPER('{{ database }}')
        AND UPPER(referenced_schema)   = UPPER('{{ schema }}')
)
SELECT
    COUNT_IF(o.object_name IN (SELECT object_name FROM objects_with_dependencies))
        AS objects_with_dependencies,
    COUNT(*) AS total_objects,
    COUNT_IF(o.object_name IN (SELECT object_name FROM objects_with_dependencies))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM objects_in_scope o
```
