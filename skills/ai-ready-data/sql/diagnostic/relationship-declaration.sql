-- diagnostic-relationship-declaration.sql
-- Lists semantic views and their relationship status
-- Returns: semantic view names with relationship coverage details

SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name AS semantic_view_name,
    t.created AS created_at,
    t.last_altered AS last_modified,
    CASE 
        WHEN t.comment LIKE '%RELATIONSHIPS%' THEN 'HAS_RELATIONSHIPS'
        ELSE 'NO_RELATIONSHIPS'
    END AS relationship_status
FROM {{ container }}.information_schema.tables t
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'SEMANTIC VIEW'
ORDER BY 
    relationship_status DESC,
    t.table_name
