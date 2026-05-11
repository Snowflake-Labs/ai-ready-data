# Check: schema_type_coverage

Fraction of columns with a semantic type indication, either via an explicit comment or a recognizable naming pattern.

## Context

Joins `information_schema.columns` against `information_schema.tables` (filtered to base tables) in the target schema. A column counts as "typed" if it has a non-empty comment (retrieved via `col_description()` from `pg_catalog`, since PostgreSQL does not expose column comments in `information_schema`) or its name matches common semantic patterns (e.g. `%_id`, `%_date`, `%amount%`). The score is the ratio of typed columns to total columns.

In PostgreSQL, all columns have explicit data types by definition. The interesting dimension beyond naming patterns is whether types are specific (e.g., `integer`, `timestamp with time zone`, `boolean`) vs. generic (`text`, `character varying` without a length constraint). Columns with generic types and no semantic annotation are the primary gap.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.ordinal_position,
        col_description(
            (quote_ident(c.table_schema) || '.' || quote_ident(c.table_name))::regclass,
            c.ordinal_position
        ) AS column_comment
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
columns_with_semantic_type AS (
    SELECT *
    FROM columns_in_scope
    WHERE
        (column_comment IS NOT NULL AND column_comment != '')
        OR LOWER(column_name) LIKE '%_id'
        OR LOWER(column_name) LIKE '%_key'
        OR LOWER(column_name) LIKE '%_date'
        OR LOWER(column_name) LIKE '%_time%'
        OR LOWER(column_name) LIKE '%_at'
        OR LOWER(column_name) LIKE '%amount%'
        OR LOWER(column_name) LIKE '%price%'
        OR LOWER(column_name) LIKE '%cost%'
        OR LOWER(column_name) LIKE '%count%'
        OR LOWER(column_name) LIKE '%quantity%'
        OR LOWER(column_name) LIKE '%total%'
        OR LOWER(column_name) LIKE '%name'
        OR LOWER(column_name) LIKE '%description'
        OR LOWER(column_name) LIKE '%status'
        OR LOWER(column_name) LIKE '%type'
        OR LOWER(column_name) LIKE '%category'
)
SELECT
    (SELECT COUNT(*) FROM columns_with_semantic_type) AS columns_with_semantic_type,
    (SELECT COUNT(*) FROM columns_in_scope) AS total_columns,
    (SELECT COUNT(*) FROM columns_with_semantic_type)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM columns_in_scope)::NUMERIC, 0) AS value
```
