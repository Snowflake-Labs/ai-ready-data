# Diagnostic: embedding_coverage

Lists tables with text content and their embedding status — whether they have an associated pgvector column.

## Context

Uses a broader set of text-column name patterns than the check query (adds `%review%`, `%summary%`, `%abstract%`, `%document%`, `%article%`, `%note%`) and joins against vector columns to surface per-table embedding status. Returns the text column name, its max length, the vector column (if any), and a recommendation when embeddings are missing.

Requires the `pgvector` extension. If not installed, all tables will report `NO_EMBEDDING`.

## SQL

```sql
WITH text_columns AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        a.attname AS text_column,
        CASE
            WHEN a.atttypmod > 0 THEN a.atttypmod - 4
            ELSE NULL
        END AS max_length
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
            OR LOWER(a.attname) LIKE '%review%'
            OR LOWER(a.attname) LIKE '%summary%'
            OR LOWER(a.attname) LIKE '%abstract%'
            OR LOWER(a.attname) LIKE '%document%'
            OR LOWER(a.attname) LIKE '%article%'
            OR LOWER(a.attname) LIKE '%note%'
        )
),
vector_columns AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        a.attname AS vector_column
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
    tc.schema_name,
    tc.table_name,
    tc.text_column,
    tc.max_length AS text_max_length,
    COALESCE(vc.vector_column, 'NONE') AS vector_column,
    CASE
        WHEN vc.vector_column IS NOT NULL THEN 'HAS_EMBEDDING'
        ELSE 'NO_EMBEDDING'
    END AS embedding_status,
    CASE
        WHEN vc.vector_column IS NOT NULL THEN 'Embedding available'
        ELSE 'Add a vector column and populate with embeddings from an embedding model (e.g., OpenAI, Sentence Transformers)'
    END AS recommendation
FROM text_columns tc
LEFT JOIN vector_columns vc
    ON tc.schema_name = vc.schema_name
    AND tc.table_name = vc.table_name
ORDER BY embedding_status DESC, tc.table_name, tc.text_column
```
