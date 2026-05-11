# Diagnostic: constraint_declaration

Lists every column in the schema with its constraint status and a remediation recommendation.

## Context

Returns one row per column across all base tables in the schema. Each row includes the column's data type, nullability, key constraint type (PRIMARY KEY, UNIQUE, FOREIGN KEY, or NONE), maximum length, numeric precision/scale, a summary constraint status, and a recommendation.

The `constraint_status` field classifies each column into one of: `PK`, `UNIQUE`, `FK`, `NOT_NULL`, `LENGTH`, `PRECISION`, or `NONE`. In PostgreSQL, `character_maximum_length` is only populated for character types with an explicit length limit (e.g. `varchar(255)`), and `numeric_precision` only for explicit numeric types — so these statuses reflect genuine user-declared constraints, unlike Snowflake which populates defaults.

All constraints in PostgreSQL are **enforced** at write time. Results are sorted with unconstrained columns (`NONE`) first, then by table name and ordinal position, so the most actionable columns appear at the top.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.ordinal_position,
        c.is_nullable,
        c.data_type,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
key_constraints AS (
    SELECT
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name,
        tc.constraint_type
    FROM information_schema.key_column_usage kcu
    INNER JOIN information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    WHERE kcu.table_schema = '{{ schema }}'
)
SELECT
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    COALESCE(kc.constraint_type, 'NONE') AS key_constraint,
    c.character_maximum_length AS max_length,
    c.numeric_precision,
    c.numeric_scale,
    CASE
        WHEN kc.constraint_type = 'PRIMARY KEY' THEN 'PK'
        WHEN kc.constraint_type = 'UNIQUE' THEN 'UNIQUE'
        WHEN kc.constraint_type = 'FOREIGN KEY' THEN 'FK'
        WHEN c.is_nullable = 'NO' THEN 'NOT_NULL'
        WHEN c.character_maximum_length IS NOT NULL THEN 'LENGTH'
        WHEN c.numeric_precision IS NOT NULL THEN 'PRECISION'
        ELSE 'NONE'
    END AS constraint_status,
    CASE
        WHEN kc.constraint_type IS NOT NULL THEN 'Has key constraint (enforced)'
        WHEN c.is_nullable = 'NO' THEN 'Has NOT NULL constraint (enforced)'
        WHEN c.character_maximum_length IS NOT NULL THEN 'Has length constraint'
        ELSE 'Consider adding constraints for data quality'
    END AS recommendation
FROM columns_in_scope c
LEFT JOIN key_constraints kc
    ON c.table_schema = kc.table_schema
    AND c.table_name = kc.table_name
    AND c.column_name = kc.column_name
ORDER BY
    constraint_status = 'NONE' DESC,
    c.table_name,
    c.ordinal_position
```
