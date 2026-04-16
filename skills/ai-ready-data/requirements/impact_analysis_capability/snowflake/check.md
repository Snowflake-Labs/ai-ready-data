# Check: impact_analysis_capability

Fraction of base tables in the schema that have at least one downstream dependent (view, materialized view, task, dynamic table, etc.).

## Context

Uses `snowflake.account_usage.object_dependencies` to count base tables with at least one tracked downstream consumer. The ratio of tables-with-dependents to total base tables is the score.

`account_usage.object_dependencies` has approximately 2-hour latency — recently created objects or dependencies may not appear yet.

A score of 1.0 means every base table in the schema has at least one tracked downstream dependent, enabling full impact analysis before schema changes.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH base_tables AS (
    SELECT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tables_with_downstream AS (
    SELECT DISTINCT UPPER(referenced_object_name) AS table_name
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referenced_database) = UPPER('{{ database }}')
        AND UPPER(referenced_schema)   = UPPER('{{ schema }}')
        AND referenced_object_domain = 'TABLE'
)
SELECT
    COUNT_IF(b.table_name IN (SELECT table_name FROM tables_with_downstream))
        AS tables_with_dependents,
    COUNT(*) AS total_tables,
    COUNT_IF(b.table_name IN (SELECT table_name FROM tables_with_downstream))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM base_tables b
```
