-- check-relationship-declaration.sql
-- Checks if tables in semantic views have relationship declarations
-- Returns: value (float 0-1) - fraction of multi-table semantic views with relationships

WITH semantic_views AS (
    SELECT
        table_catalog,
        table_schema,
        table_name,
        comment
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'SEMANTIC VIEW'
),
-- Count tables referenced in each semantic view via SHOW command would be ideal
-- but we approximate by checking if RELATIONSHIPS keyword exists in definition
view_relationships AS (
    SELECT
        sv.table_name AS semantic_view_name,
        -- Check if relationships are declared (approximate via definition check)
        CASE 
            WHEN sv.comment LIKE '%RELATIONSHIPS%' THEN 1
            ELSE 0
        END AS has_relationships
    FROM semantic_views sv
)
SELECT
    COUNT_IF(has_relationships = 1) AS views_with_relationships,
    COUNT(*) AS total_semantic_views,
    COUNT_IF(has_relationships = 1)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM view_relationships
