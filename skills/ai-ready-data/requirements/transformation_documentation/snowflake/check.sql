-- check-transformation-documentation.sql
-- Checks if views/dynamic tables have documented transformation logic
-- Returns: value (float 0-1) - fraction of transformations with documentation

WITH transformations AS (
    SELECT
        table_name,
        table_type,
        comment
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('VIEW', 'DYNAMIC TABLE', 'MATERIALIZED VIEW')
),
documented_transformations AS (
    SELECT * FROM transformations
    WHERE comment IS NOT NULL AND LENGTH(comment) > 20
)
SELECT
    (SELECT COUNT(*) FROM documented_transformations) AS documented_count,
    (SELECT COUNT(*) FROM transformations) AS total_count,
    (SELECT COUNT(*) FROM documented_transformations)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM transformations)::FLOAT, 0) AS value
