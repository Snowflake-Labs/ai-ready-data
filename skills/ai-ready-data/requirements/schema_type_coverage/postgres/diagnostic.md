# Diagnostic: schema_type_coverage

Per-column breakdown of inferred semantic types and documentation status.

## Context

Lists every column in the schema's base tables with its physical data type, an inferred semantic type derived from naming conventions and data type (e.g. `IDENTIFIER`, `TEMPORAL`, `MEASURE`, `CATEGORICAL`, `FLAG`, `TEXT_CONTENT`), and whether the column has an explicit comment. Columns that don't match any pattern are marked `UNKNOWN`.

PostgreSQL does not expose column comments in `information_schema.columns`. Comments are retrieved via `col_description()` from `pg_catalog`. Use this output to identify which columns lack semantic context and would benefit from `COMMENT ON COLUMN` statements.

## SQL

```sql
SELECT
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    CASE
        WHEN LOWER(c.column_name) LIKE '%_id' OR LOWER(c.column_name) LIKE '%_key' THEN 'IDENTIFIER'
        WHEN LOWER(c.column_name) = 'id' OR LOWER(c.column_name) = 'key' THEN 'IDENTIFIER'

        WHEN c.data_type IN ('date', 'timestamp without time zone', 'timestamp with time zone',
                             'time without time zone', 'time with time zone') THEN 'TEMPORAL'
        WHEN LOWER(c.column_name) LIKE '%_date' OR LOWER(c.column_name) LIKE '%_at' THEN 'TEMPORAL'

        WHEN LOWER(c.column_name) LIKE '%amount%' OR LOWER(c.column_name) LIKE '%price%' THEN 'MEASURE'
        WHEN LOWER(c.column_name) LIKE '%cost%' OR LOWER(c.column_name) LIKE '%total%' THEN 'MEASURE'
        WHEN LOWER(c.column_name) LIKE '%count%' OR LOWER(c.column_name) LIKE '%quantity%' THEN 'MEASURE'
        WHEN LOWER(c.column_name) LIKE '%rate%' OR LOWER(c.column_name) LIKE '%percent%' THEN 'MEASURE'
        WHEN c.data_type IN ('numeric', 'real', 'double precision') AND c.is_nullable = 'YES' THEN 'LIKELY_MEASURE'

        WHEN LOWER(c.column_name) LIKE '%name' OR LOWER(c.column_name) LIKE '%description' THEN 'ATTRIBUTE'
        WHEN LOWER(c.column_name) LIKE '%status' OR LOWER(c.column_name) LIKE '%type' THEN 'CATEGORICAL'
        WHEN LOWER(c.column_name) LIKE '%category' OR LOWER(c.column_name) LIKE '%code' THEN 'CATEGORICAL'
        WHEN LOWER(c.column_name) LIKE '%flag' OR LOWER(c.column_name) LIKE '%is_%' THEN 'FLAG'
        WHEN c.data_type = 'boolean' THEN 'FLAG'

        WHEN c.data_type IN ('character varying', 'text') AND
             (LOWER(c.column_name) LIKE '%text%' OR LOWER(c.column_name) LIKE '%content%' OR
              LOWER(c.column_name) LIKE '%body%' OR LOWER(c.column_name) LIKE '%message%') THEN 'TEXT_CONTENT'

        ELSE 'UNKNOWN'
    END AS inferred_semantic_type,
    CASE
        WHEN col_description(
            (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass,
            c.ordinal_position
        ) IS NOT NULL THEN 'DOCUMENTED'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    COALESCE(
        col_description(
            (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass,
            c.ordinal_position
        ),
        ''
    ) AS current_comment
FROM information_schema.columns c
INNER JOIN information_schema.tables t
    ON c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY
    c.table_name,
    c.ordinal_position
```
