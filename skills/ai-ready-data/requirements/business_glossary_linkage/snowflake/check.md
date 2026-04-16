# Check: business_glossary_linkage

Fraction of columns (across base tables in the schema) that have either a column-level tag or a non-trivial comment.

## Context

Business glossary linkage in Snowflake is detected through two signals:

1. **Object tags** (`snowflake.account_usage.tag_references`, `domain = 'COLUMN'`) — primary signal, indicates a formal glossary term has been attached.
2. **Column comments longer than 20 characters** — secondary signal, indicates at least some documentation effort. The 20-character threshold filters out trivial comments like "ID" or "name" that don't constitute a real glossary definition.

A column counts as linked if it has **either** signal. `account_usage.tag_references` has approximately 2-hour latency for new tags.

Returns NULL (N/A) when the schema contains no columns in base tables.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_name,
        c.column_name,
        c.comment
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name   = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT DISTINCT
        UPPER(object_name) AS table_name,
        UPPER(column_name) AS column_name
    FROM snowflake.account_usage.tag_references
    WHERE UPPER(object_database) = UPPER('{{ database }}')
        AND UPPER(object_schema)   = UPPER('{{ schema }}')
        AND domain = 'COLUMN'
),
classified AS (
    SELECT
        CASE
            WHEN tc.column_name IS NOT NULL                          THEN 1
            WHEN c.comment IS NOT NULL AND LENGTH(c.comment) > 20    THEN 1
            ELSE 0
        END AS is_linked
    FROM columns_in_scope c
    LEFT JOIN tagged_columns tc
        ON UPPER(c.table_name)  = tc.table_name
       AND UPPER(c.column_name) = tc.column_name
)
SELECT
    SUM(is_linked) AS columns_with_glossary,
    COUNT(*)       AS total_columns,
    SUM(is_linked)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM classified
```
