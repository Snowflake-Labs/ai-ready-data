-- diagnostic-dependency-graph.sql
-- Shows upstream and downstream dependencies for tables
-- Returns: dependency relationships

SELECT
    referencing_database || '.' || referencing_schema || '.' || referencing_object_name AS dependent_object,
    referencing_object_domain AS dependent_type,
    referenced_database || '.' || referenced_schema || '.' || referenced_object_name AS source_object,
    referenced_object_domain AS source_type,
    'UPSTREAM' AS direction
FROM snowflake.account_usage.object_dependencies
WHERE (referencing_database = '{{ container }}' AND referencing_schema = '{{ namespace }}')
    OR (referenced_database = '{{ container }}' AND referenced_schema = '{{ namespace }}')

UNION ALL

SELECT
    referenced_database || '.' || referenced_schema || '.' || referenced_object_name AS dependent_object,
    referenced_object_domain AS dependent_type,
    referencing_database || '.' || referencing_schema || '.' || referencing_object_name AS source_object,
    referencing_object_domain AS source_type,
    'DOWNSTREAM' AS direction
FROM snowflake.account_usage.object_dependencies
WHERE referenced_database = '{{ container }}' 
    AND referenced_schema = '{{ namespace }}'

ORDER BY direction, dependent_object
LIMIT 200
