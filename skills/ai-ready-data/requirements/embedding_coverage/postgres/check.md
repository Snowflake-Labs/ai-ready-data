# Check: embedding_coverage

Fraction of unstructured data assets with pre-computed vector embeddings available for retrieval.

## Context

Scans `pg_attribute` and `pg_type` for text-heavy columns (names matching common patterns like `%text%`, `%content%`, `%description%`, etc.) in base tables, then checks whether those tables also contain a `vector` column (pgvector). Tables with no text columns yield a score of 1.0 (vacuously true). The score is the ratio of text-bearing tables that also have at least one vector column.

Requires the `pgvector` extension (`CREATE EXTENSION IF NOT EXISTS vector`). If pgvector is not installed, no columns will have type `vector` and the check will reflect that gap.

## SQL

```sql
WITH text_columns AS (
    SELECT DISTINCT c.relname AS table_name
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND t.typname IN ('text', 'varchar', 'bpchar')
        AND (
            LOWER(a.attname) LIKE '%text%'
            OR LOWER(a.attname) LIKE '%content%'
            OR LOWER(a.attname) LIKE '%description%'
            OR LOWER(a.attname) LIKE '%body%'
            OR LOWER(a.attname) LIKE '%message%'
            OR LOWER(a.attname) LIKE '%comment%'
        )
),
vector_tables AS (
    SELECT DISTINCT c.relname AS table_name
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND t.typname = 'vector'
)
SELECT
    (SELECT COUNT(*) FROM text_columns tc
     WHERE tc.table_name IN (SELECT table_name FROM vector_tables)) AS tables_with_embeddings,
    (SELECT COUNT(*) FROM text_columns) AS tables_with_text_content,
    CASE
        WHEN (SELECT COUNT(*) FROM text_columns) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM text_columns tc
              WHERE tc.table_name IN (SELECT table_name FROM vector_tables))::NUMERIC
             / (SELECT COUNT(*) FROM text_columns)::NUMERIC
    END AS value
```
