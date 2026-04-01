# Check: embedding_dimension_consistency

Fraction of embedding collections with uniform dimensionality matching their consuming model's expected input.

## Context

Extracts all `vector` columns from `pg_attribute` in the target schema. In pgvector, the dimension is encoded in `atttypmod` — when `atttypmod > 0`, the dimension equals `atttypmod`. Groups by dimension, then measures how many columns share the most common dimension versus the total. A score of 1.0 means every vector column uses the same dimension.

Requires the `pgvector` extension.

## SQL

```sql
WITH vector_dims AS (
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
mode_dim AS (
    SELECT dimension, COUNT(*) AS cnt
    FROM vector_dims
    WHERE dimension IS NOT NULL
    GROUP BY dimension
    ORDER BY cnt DESC
    LIMIT 1
),
total_vectors AS (
    SELECT COUNT(*) AS cnt FROM vector_dims
)
SELECT
    (SELECT cnt FROM total_vectors) AS total_vector_columns,
    (SELECT COUNT(*) FROM vector_dims vd, mode_dim md
     WHERE vd.dimension = md.dimension) AS columns_with_common_dimension,
    (SELECT COUNT(*) FROM vector_dims vd, mode_dim md
     WHERE vd.dimension = md.dimension)::NUMERIC
        / NULLIF((SELECT cnt FROM total_vectors)::NUMERIC, 0) AS value
```
