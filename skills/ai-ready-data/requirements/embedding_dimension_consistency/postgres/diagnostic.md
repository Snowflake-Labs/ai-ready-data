# Diagnostic: embedding_dimension_consistency

Lists every vector column in the schema with its dimension, flags whether it matches the most common dimension, and provides a recommendation.

## Context

Identifies the most common `vector` dimension across all vector columns and marks each column as `CONSISTENT` or `INCONSISTENT`. Columns with a different dimension than the majority may cause failures in vector similarity search or require re-embedding before use.

In pgvector, the dimension is encoded in `atttypmod` — when `atttypmod > 0`, the dimension equals `atttypmod`. Columns defined as bare `vector` (no dimension specified) will show a NULL dimension.

Requires the `pgvector` extension.

## SQL

```sql
WITH vector_columns AS (
    SELECT
        c.relname AS table_name,
        a.attname AS column_name,
        format_type(a.atttypid, a.atttypmod) AS vector_type,
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
dimension_summary AS (
    SELECT dimension, COUNT(*) AS column_count
    FROM vector_columns
    WHERE dimension IS NOT NULL
    GROUP BY dimension
),
most_common AS (
    SELECT dimension
    FROM dimension_summary
    ORDER BY column_count DESC
    LIMIT 1
)
SELECT
    '{{ schema }}' AS schema_name,
    v.table_name,
    v.column_name,
    v.vector_type,
    v.dimension,
    CASE
        WHEN v.dimension = (SELECT dimension FROM most_common) THEN 'CONSISTENT'
        ELSE 'INCONSISTENT'
    END AS dimension_status,
    CASE
        WHEN v.dimension = (SELECT dimension FROM most_common) THEN 'Matches most common dimension'
        WHEN v.dimension IS NULL THEN 'No dimension constraint — consider adding one'
        ELSE 'Different dimension — may cause issues with vector search'
    END AS recommendation
FROM vector_columns v
ORDER BY dimension_status DESC, v.table_name, v.column_name
```
