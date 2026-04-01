# Check: embedding_dimension_consistency

Fraction of embedding collections with uniform dimensionality matching their consuming model's expected input.

## Context

Extracts all pgvector `vector` columns from `pg_attribute` in the target schema. In pgvector, the dimension is encoded in `atttypmod` — when `atttypmod > 0`, the dimension equals `atttypmod`. Groups by dimension, then measures how many columns share the most common dimension versus the total. A score of 1.0 means every vector column uses the same dimension.

Requires the `pgvector` extension. If not installed, no vector columns will be found.

## SQL

```sql
WITH vector_columns AS (
    SELECT
        c.relname AS table_name,
        a.attname AS column_name,
        CASE WHEN a.atttypmod > 0 THEN a.atttypmod ELSE NULL END AS dimension
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND t.typname = 'vector'
),
dimension_counts AS (
    SELECT dimension, COUNT(*) AS column_count
    FROM vector_columns
    WHERE dimension IS NOT NULL
    GROUP BY dimension
),
most_common_dimension AS (
    SELECT dimension, column_count
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
    (SELECT column_count FROM most_common_dimension)::NUMERIC
        / NULLIF((SELECT cnt FROM total_vectors)::NUMERIC, 0) AS value
```
