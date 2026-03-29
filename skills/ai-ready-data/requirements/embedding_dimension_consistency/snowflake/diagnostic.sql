-- diagnostic-embedding-dimension-consistency.sql
-- Lists vector columns with their dimensions
-- Returns: vector columns with dimension details

WITH vector_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type AS vector_type,
        c.comment
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type LIKE 'VECTOR%'
),
dimension_summary AS (
    SELECT
        vector_type,
        COUNT(*) AS column_count
    FROM vector_columns
    GROUP BY vector_type
),
most_common AS (
    SELECT vector_type
    FROM dimension_summary
    ORDER BY column_count DESC
    LIMIT 1
)
SELECT
    v.table_catalog AS database_name,
    v.table_schema AS schema_name,
    v.table_name,
    v.column_name,
    v.vector_type,
    CASE
        WHEN v.vector_type = (SELECT vector_type FROM most_common) THEN 'CONSISTENT'
        ELSE 'INCONSISTENT'
    END AS dimension_status,
    CASE
        WHEN v.vector_type = (SELECT vector_type FROM most_common) THEN 'Matches most common dimension'
        ELSE 'Different dimension - may cause issues with vector search'
    END AS recommendation,
    v.comment
FROM vector_columns v
ORDER BY dimension_status DESC, v.table_name, v.column_name
