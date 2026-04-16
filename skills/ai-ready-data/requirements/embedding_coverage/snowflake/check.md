# Check: embedding_coverage

Fraction of text-bearing base tables that also have at least one `VECTOR` column (pre-computed embeddings co-located with the source text).

## Context

Text-bearing tables are identified by name pattern (columns matching `text`, `content`, `description`, `body`, `message`, `comment`) with a text-typed column. The score is the ratio of text-bearing tables that also contain a vector column in the same table.

Returns NULL (N/A) when the schema contains no text-bearing tables. If this appears as N/A and you still want embedding coverage, the schema may be using non-standard text column names — widen the regex in a profile override.

## SQL

```sql
WITH text_tables AS (
    SELECT DISTINCT UPPER(c.table_name) AS table_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
      ON c.table_catalog = t.table_catalog
     AND c.table_schema  = t.table_schema
     AND c.table_name    = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
      AND t.table_type = 'BASE TABLE'
      AND UPPER(c.data_type) IN ('TEXT','VARCHAR','STRING')
      AND REGEXP_LIKE(
          LOWER(c.column_name),
          '.*(text|content|description|body|message|comment).*'
      )
),
vector_tables AS (
    SELECT DISTINCT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.columns
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND data_type LIKE 'VECTOR%'
)
SELECT
    COUNT_IF(t.table_name IN (SELECT table_name FROM vector_tables))
        AS tables_with_embeddings,
    COUNT(*) AS tables_with_text_content,
    COUNT_IF(t.table_name IN (SELECT table_name FROM vector_tables))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM text_tables t
```
