# Check: embedding_coverage

Fraction of unstructured data assets with pre-computed vector embeddings available for retrieval.

## Context

Scans `information_schema.columns` for text-heavy columns (names matching common patterns like `%text%`, `%content%`, `%description%`, etc.) in base tables, then checks whether those tables also contain a `VECTOR` column. Tables with no text columns yield a score of 1.0 (vacuously true). The score is the ratio of text-bearing tables that also have at least one vector column.

## SQL

```sql
WITH text_columns AS (
    SELECT
        c.table_name,
        c.column_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
      ON c.table_catalog = t.table_catalog
     AND c.table_schema = t.table_schema
     AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
      AND t.table_type = 'BASE TABLE'
      AND c.data_type IN ('VARCHAR', 'TEXT', 'STRING')
      AND (
        LOWER(c.column_name) LIKE '%text%'
        OR LOWER(c.column_name) LIKE '%content%'
        OR LOWER(c.column_name) LIKE '%description%'
        OR LOWER(c.column_name) LIKE '%body%'
        OR LOWER(c.column_name) LIKE '%message%'
        OR LOWER(c.column_name) LIKE '%comment%'
      )
),
vector_columns AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.columns
    WHERE table_schema = '{{ schema }}'
      AND data_type LIKE 'VECTOR%'
),
tables_with_text AS (
    SELECT DISTINCT table_name FROM text_columns
)
SELECT
    (SELECT COUNT(*) FROM vector_columns) AS tables_with_embeddings,
    (SELECT COUNT(*) FROM tables_with_text) AS tables_with_text_content,
    CASE
      WHEN (SELECT COUNT(*) FROM tables_with_text) = 0 THEN 1.0
      ELSE (
        SELECT COUNT(*)
        FROM tables_with_text t
        WHERE t.table_name IN (SELECT table_name FROM vector_columns)
      )::FLOAT / (SELECT COUNT(*) FROM tables_with_text)::FLOAT
    END AS value
```