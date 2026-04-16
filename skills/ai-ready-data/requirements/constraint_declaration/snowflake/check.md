# Check: constraint_declaration

Fraction of columns (in base tables) with at least one explicitly declared constraint: NOT NULL, PRIMARY KEY membership, UNIQUE membership, a CHECK constraint, or a comment that declares a valid range.

## Context

A column counts as "constrained" when **any** of the following is true:

1. `is_nullable = 'NO'` (captures both explicit NOT NULL and PK-implied NOT NULL).
2. It appears in a PRIMARY KEY or UNIQUE constraint in `information_schema.key_column_usage`.
3. It appears in a CHECK constraint via `information_schema.check_constraints` + `key_column_usage`.
4. Its comment mentions a range declaration (keywords like `range`, `min`, `max`, `between`, `allowed`, or explicit `N-M` / `N to M` numeric bounds).

Primary key, unique, and foreign key constraints in Snowflake are **not enforced** — they are metadata hints only. They still count here because they express model intent, which is valuable for AI consumers. NOT NULL **is** enforced; CHECK constraints are **not** enforced and are rarely populated in Snowflake in practice, but any that exist count toward the score.

`character_maximum_length` and `numeric_precision` are intentionally excluded — Snowflake always populates these with permissive defaults (e.g. VARCHAR → 16,777,216) so they don't represent user intent.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.is_nullable,
        c.comment
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
      AND t.table_type = 'BASE TABLE'
),
constrained_key_columns AS (
    SELECT DISTINCT
        UPPER(kcu.table_schema) AS table_schema,
        UPPER(kcu.table_name)   AS table_name,
        UPPER(kcu.column_name)  AS column_name
    FROM {{ database }}.information_schema.table_constraints tc
    JOIN {{ database }}.information_schema.key_column_usage kcu
      ON tc.constraint_catalog = kcu.constraint_catalog
     AND tc.constraint_schema = kcu.constraint_schema
     AND tc.constraint_name  = kcu.constraint_name
    WHERE UPPER(tc.table_schema) = UPPER('{{ schema }}')
      AND tc.constraint_type IN ('PRIMARY KEY','UNIQUE','CHECK')
),
classified AS (
    SELECT
        CASE
            WHEN c.is_nullable = 'NO' THEN 1
            WHEN EXISTS (
                SELECT 1 FROM constrained_key_columns k
                WHERE k.table_schema = UPPER(c.table_schema)
                  AND k.table_name   = UPPER(c.table_name)
                  AND k.column_name  = UPPER(c.column_name)
            ) THEN 1
            WHEN c.comment IS NOT NULL
                 AND REGEXP_LIKE(
                     LOWER(c.comment),
                     '.*(range|min |max |between|allowed|[0-9]+\\s*(to|-)\\s*[0-9]+).*'
                 ) THEN 1
            ELSE 0
        END AS is_constrained
    FROM columns_in_scope c
)
SELECT
    SUM(is_constrained) AS columns_with_constraints,
    COUNT(*) AS total_columns,
    SUM(is_constrained)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM classified
```
