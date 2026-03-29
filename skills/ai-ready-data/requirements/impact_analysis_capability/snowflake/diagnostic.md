# Diagnostic: impact_analysis_capability

Lists every base table in the schema with its downstream dependent count and dependent object details.

## Context

Joins `information_schema.tables` with `snowflake.account_usage.object_dependencies` to show each table's downstream dependents. Tables with `NO_DEPENDENTS_TRACKED` have no recorded downstream objects — schema changes to these tables cannot be impact-assessed automatically.

`account_usage.object_dependencies` has approximately 2-hour latency.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    COALESCE(d.downstream_count, 0) AS downstream_dependents,
    COALESCE(d.dependent_objects, 'none') AS dependent_objects,
    CASE
        WHEN d.downstream_count > 0 THEN 'HAS_DEPENDENTS'
        ELSE 'NO_DEPENDENTS_TRACKED'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN (
    SELECT
        referenced_object_name AS table_name,
        COUNT(DISTINCT referencing_object_name) AS downstream_count,
        LISTAGG(DISTINCT referencing_object_domain || ':' || referencing_object_name, ', ') AS dependent_objects
    FROM snowflake.account_usage.object_dependencies
    WHERE UPPER(referenced_database) = UPPER('{{ database }}')
        AND UPPER(referenced_schema) = UPPER('{{ schema }}')
        AND referenced_object_domain = 'TABLE'
    GROUP BY referenced_object_name
) d ON t.table_name = d.table_name
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY downstream_dependents DESC, t.table_name
```