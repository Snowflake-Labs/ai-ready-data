# Check: constraint_declaration

Fraction of columns in the schema with explicitly declared constraints (NOT NULL or key constraints).

## Context

Scopes to all columns in base tables within the target schema. A column counts as "constrained" if it has `is_nullable = 'NO'` or appears in `key_column_usage` (primary key, unique, or foreign key).

`character_maximum_length` and `numeric_precision` are intentionally excluded because Snowflake always populates these with defaults (e.g., VARCHAR defaults to 16,777,216). Only explicit, user-declared constraints count.

Primary key and unique constraints in Snowflake are **not enforced** — they are metadata hints only. They still count toward this check because they express developer intent about the data model, which is valuable for AI workloads even without enforcement.

NOT NULL constraints **are** enforced by Snowflake. Adding a NOT NULL constraint will fail if the column currently contains NULLs — fill or delete them first.

Returns a float 0–1 representing the fraction of constrained columns.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.is_nullable
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
constrained_columns AS (
    SELECT DISTINCT
        kcu.table_catalog,
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM {{ database }}.information_schema.key_column_usage kcu
    WHERE kcu.table_schema = '{{ schema }}'
)
SELECT
    COUNT_IF(
        c.is_nullable = 'NO'
        OR cc.column_name IS NOT NULL
    ) AS columns_with_constraints,
    COUNT(*) AS total_columns,
    COUNT_IF(
        c.is_nullable = 'NO'
        OR cc.column_name IS NOT NULL
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM columns_in_scope c
LEFT JOIN constrained_columns cc
    ON c.table_catalog = cc.table_catalog
    AND c.table_schema = cc.table_schema
    AND c.table_name = cc.table_name
    AND c.column_name = cc.column_name
```
