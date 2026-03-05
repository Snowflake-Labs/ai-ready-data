-- check-embedding-dimension-consistency.sql
-- Checks if all vector columns have consistent dimensions
-- Returns: value (float 0-1) - 1.0 if all vectors have same dimension, lower if mixed

WITH vector_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        -- Extract dimension from data type (e.g., VECTOR(FLOAT, 768))
        c.data_type AS full_type,
        c.comment
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type LIKE 'VECTOR%'
),
dimension_counts AS (
    SELECT
        full_type,
        COUNT(*) AS column_count
    FROM vector_columns
    GROUP BY full_type
),
most_common_dimension AS (
    SELECT full_type, column_count
    FROM dimension_counts
    ORDER BY column_count DESC
    LIMIT 1
),
total_vectors AS (
    SELECT COUNT(*) AS cnt FROM vector_columns
)
SELECT
    (SELECT cnt FROM total_vectors) AS total_vector_columns,
    (SELECT column_count FROM most_common_dimension) AS columns_with_common_dimension,
    (SELECT column_count FROM most_common_dimension)::FLOAT / 
        NULLIF((SELECT cnt FROM total_vectors)::FLOAT, 0) AS value
