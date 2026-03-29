# Check: embedding_dimension_consistency

Fraction of embedding collections with uniform dimensionality matching their consuming model's expected input.

## Context

Extracts all `VECTOR` columns from `information_schema.columns` in the target schema. Groups by `data_type` (which encodes both element type and dimension, e.g. `VECTOR(FLOAT, 768)`), then measures how many columns share the most common dimension versus the total. A score of 1.0 means every vector column uses the same type and dimension.

## SQL

```sql
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
```