# Diagnostic: unit_of_measure_declaration

Lists numeric columns and their unit of measure status.

## Context

Returns every measured numeric column with its inferred unit category (monetary, percentage, weight, length, time, temperature, or unknown), documentation status, current comment text, and a recommendation for remediation. Columns likely to be identifiers, keys, counts, or flags are excluded.

PostgreSQL column comments are retrieved via `col_description()` from `pg_catalog`. Use this to identify which columns need unit-of-measure annotations added via `COMMENT ON COLUMN` or column renaming.

## SQL

```sql
WITH numeric_columns AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.numeric_precision,
        c.numeric_scale,
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
        AND c.data_type IN ('integer', 'bigint', 'smallint', 'numeric', 'real', 'double precision', 'decimal')
        AND LOWER(c.column_name) NOT LIKE '%_id'
        AND LOWER(c.column_name) NOT LIKE '%_key'
        AND LOWER(c.column_name) NOT LIKE '%count%'
        AND LOWER(c.column_name) NOT LIKE '%flag%'
        AND LOWER(c.column_name) NOT LIKE '%is_%'
)
SELECT
    n.table_schema AS schema_name,
    n.table_name,
    n.column_name,
    n.data_type,
    n.numeric_precision,
    n.numeric_scale,
    CASE
        WHEN LOWER(n.column_name) LIKE '%amount%' OR LOWER(n.column_name) LIKE '%price%'
             OR LOWER(n.column_name) LIKE '%cost%' OR LOWER(n.column_name) LIKE '%revenue%'
             OR LOWER(n.column_name) LIKE '%total%' THEN 'MONETARY'
        WHEN LOWER(n.column_name) LIKE '%rate%' OR LOWER(n.column_name) LIKE '%pct%'
             OR LOWER(n.column_name) LIKE '%percent%' OR LOWER(n.column_name) LIKE '%ratio%' THEN 'PERCENTAGE'
        WHEN LOWER(n.column_name) LIKE '%weight%' OR LOWER(n.column_name) LIKE '%mass%' THEN 'WEIGHT'
        WHEN LOWER(n.column_name) LIKE '%length%' OR LOWER(n.column_name) LIKE '%height%'
             OR LOWER(n.column_name) LIKE '%width%' OR LOWER(n.column_name) LIKE '%distance%' THEN 'LENGTH'
        WHEN LOWER(n.column_name) LIKE '%duration%' OR LOWER(n.column_name) LIKE '%seconds%'
             OR LOWER(n.column_name) LIKE '%minutes%' OR LOWER(n.column_name) LIKE '%hours%' THEN 'TIME'
        WHEN LOWER(n.column_name) LIKE '%temp%' THEN 'TEMPERATURE'
        ELSE 'UNKNOWN'
    END AS inferred_unit_category,
    CASE
        WHEN n.column_comment IS NOT NULL AND LENGTH(n.column_comment) > 0 THEN 'HAS_COMMENT'
        ELSE 'NO_COMMENT'
    END AS documentation_status,
    COALESCE(n.column_comment, '') AS current_comment,
    CASE
        WHEN n.column_comment IS NOT NULL AND (
            LOWER(n.column_comment) LIKE '%usd%' OR LOWER(n.column_comment) LIKE '%dollar%'
            OR LOWER(n.column_comment) LIKE '%percent%' OR LOWER(n.column_comment) LIKE '%unit%'
        ) THEN 'Unit documented in comment'
        WHEN LOWER(n.column_name) LIKE '%_usd' OR LOWER(n.column_name) LIKE '%_pct' THEN 'Unit in column name'
        ELSE 'Add unit of measure to COMMENT (e.g., "Amount in USD")'
    END AS recommendation
FROM numeric_columns n
ORDER BY
    documentation_status DESC,
    n.table_name,
    n.ordinal_position
```
