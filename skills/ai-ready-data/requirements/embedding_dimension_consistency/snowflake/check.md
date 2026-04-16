# Check: embedding_dimension_consistency

Fraction of vector columns in the schema that share the most common `(element_type, dimension)` signature.

## Context

Extracts all `VECTOR` columns from `information_schema.columns` in the target schema. Groups by `data_type` (which encodes both element type and dimension, e.g. `VECTOR(FLOAT, 768)`) and measures how many columns share the most common group versus the total. A score of 1.0 means every vector column uses the same type and dimension.

Ties in the "most common" group are broken by `data_type` ascending — keeps runs deterministic across repeated invocations.

Returns NULL (N/A) when the schema contains no vector columns.

## SQL

```sql
WITH vector_columns AS (
    SELECT c.data_type AS full_type
    FROM {{ database }}.information_schema.columns c
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND c.data_type LIKE 'VECTOR%'
),
dimension_counts AS (
    SELECT full_type, COUNT(*) AS column_count
    FROM vector_columns
    GROUP BY full_type
),
most_common AS (
    SELECT full_type, column_count
    FROM dimension_counts
    ORDER BY column_count DESC, full_type ASC
    LIMIT 1
),
total_vectors AS (
    SELECT COUNT(*) AS cnt FROM vector_columns
)
SELECT
    (SELECT cnt FROM total_vectors)                   AS total_vector_columns,
    (SELECT column_count FROM most_common)            AS columns_with_common_dimension,
    (SELECT column_count FROM most_common)::FLOAT
        / NULLIF((SELECT cnt FROM total_vectors)::FLOAT, 0) AS value
```
