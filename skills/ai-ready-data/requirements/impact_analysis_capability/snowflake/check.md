# Check: impact_analysis_capability

Fraction of datasets for which the downstream impact of a schema or content change can be automatically enumerated.

## Context

Uses `snowflake.account_usage.object_dependencies` to count how many base tables in the schema have at least one downstream dependent (view, materialized view, task, etc.). The ratio of tables-with-dependents to total tables is the score.

`account_usage.object_dependencies` has approximately 2-hour latency — recently created objects or dependencies may not appear yet.

A score of 1.0 means every base table in the schema has at least one tracked downstream dependent, enabling full impact analysis before schema changes.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_downstream AS (
    SELECT COUNT(DISTINCT referencing_object_name) AS cnt
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referenced_database) = UPPER('{{ database }}')
        AND UPPER(referenced_schema) = UPPER('{{ schema }}')
        AND referenced_object_domain = 'TABLE'
)
SELECT
    tables_with_downstream.cnt AS tables_with_dependents,
    table_count.cnt AS total_tables,
    tables_with_downstream.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tables_with_downstream
```