# Check: business_glossary_linkage

Fraction of columns linked to a business glossary or authoritative term definition.

## Context

Business glossary linkage in Snowflake is detected through two signals:
1. **Object tags** (`tag_references` view) — primary signal, indicates a formal glossary term has been attached
2. **Column comments with meaningful descriptions** (>20 characters) — secondary signal, indicates at least some documentation effort

A column counts as linked if it has any column-level tag OR a comment longer than 20 characters. The 20-character threshold filters out trivial comments like "ID" or "name" that don't constitute a real glossary definition.

`account_usage.tag_references` has approximately 2-hour latency for new tags.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_name,
        c.column_name,
        c.comment
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT DISTINCT
        UPPER(object_name) AS table_name,
        UPPER(column_name) AS column_name
    FROM snowflake.account_usage.tag_references
    WHERE UPPER(object_database) = UPPER('{{ database }}')
        AND UPPER(object_schema) = UPPER('{{ schema }}')
        AND domain = 'COLUMN'
)
SELECT
    COUNT_IF(
        tc.column_name IS NOT NULL
        OR (c.comment IS NOT NULL AND LENGTH(c.comment) > 20)
    ) AS columns_with_glossary,
    COUNT(*) AS total_columns,
    COUNT_IF(
        tc.column_name IS NOT NULL
        OR (c.comment IS NOT NULL AND LENGTH(c.comment) > 20)
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM columns_in_scope c
LEFT JOIN tagged_columns tc
    ON UPPER(c.table_name) = tc.table_name
    AND UPPER(c.column_name) = tc.column_name
```
