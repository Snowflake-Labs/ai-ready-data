# Check: constraint_declaration

Fraction of columns in the schema with explicitly declared constraints (NOT NULL or key constraints).

## Context

Scopes to all columns in base tables within the target schema. A column counts as "constrained" if it has `is_nullable = 'NO'` or appears in `key_column_usage` (primary key, unique, or foreign key).

Unlike Snowflake where primary key and unique constraints are metadata-only hints, PostgreSQL **enforces all constraints** at write time. Adding a NOT NULL constraint will fail if the column contains NULLs. Adding a PRIMARY KEY will fail if duplicates or NULLs exist. This means a high constraint coverage score in PostgreSQL provides stronger guarantees about data quality.

Returns a float 0–1 representing the fraction of constrained columns.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.is_nullable
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
constrained_columns AS (
    SELECT DISTINCT
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM information_schema.key_column_usage kcu
    WHERE kcu.table_schema = '{{ schema }}'
)
SELECT
    COUNT(*) FILTER (WHERE
        c.is_nullable = 'NO'
        OR cc.column_name IS NOT NULL
    ) AS columns_with_constraints,
    COUNT(*) AS total_columns,
    COUNT(*) FILTER (WHERE
        c.is_nullable = 'NO'
        OR cc.column_name IS NOT NULL
    )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM columns_in_scope c
LEFT JOIN constrained_columns cc
    ON c.table_schema = cc.table_schema
    AND c.table_name = cc.table_name
    AND c.column_name = cc.column_name
```
