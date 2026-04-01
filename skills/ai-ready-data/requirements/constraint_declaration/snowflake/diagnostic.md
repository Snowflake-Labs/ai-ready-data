# Diagnostic: constraint_declaration

Lists every column in the schema with its constraint status and a remediation recommendation.

## Context

Returns one row per column across all base tables in the schema. Each row includes the column's data type, nullability, key constraint type (PRIMARY KEY, UNIQUE, FOREIGN KEY, or NONE), a summary constraint status, and a recommendation.

Snowflake does not have `information_schema.key_column_usage`. This diagnostic uses `SHOW PRIMARY KEYS` and `SHOW UNIQUE KEYS` to get column-level key membership, then joins that to `information_schema.columns`. The `SHOW` commands and subsequent queries must run in the **same session**.

The `constraint_status` field classifies each column into one of: `PK`, `UNIQUE`, `FK`, `NOT_NULL`, or `NONE`. `LENGTH` and `PRECISION` are excluded because Snowflake always populates `character_maximum_length` and `numeric_precision` with defaults.

Results are sorted with unconstrained columns (`NONE`) first, then by table name and ordinal position, so the most actionable columns appear at the top.

Primary key and unique constraints in Snowflake are **not enforced** — they are metadata hints only. Foreign key constraints are also declarative and not enforced.

## SQL

Run all statements in the same session.

```sql
SHOW PRIMARY KEYS IN SCHEMA {{ database }}.{{ schema }};

CREATE OR REPLACE TEMPORARY TABLE _pk_cols AS
SELECT "table_name" AS table_name, "column_name" AS column_name, 'PRIMARY KEY' AS constraint_type
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW UNIQUE KEYS IN SCHEMA {{ database }}.{{ schema }};

CREATE OR REPLACE TEMPORARY TABLE _uq_cols AS
SELECT "table_name" AS table_name, "column_name" AS column_name, 'UNIQUE' AS constraint_type
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW IMPORTED KEYS IN SCHEMA {{ database }}.{{ schema }};

CREATE OR REPLACE TEMPORARY TABLE _fk_cols AS
SELECT "fk_table_name" AS table_name, "fk_column_name" AS column_name, 'FOREIGN KEY' AS constraint_type
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

WITH key_constraints AS (
    SELECT table_name, column_name, constraint_type FROM _pk_cols
    UNION ALL
    SELECT table_name, column_name, constraint_type FROM _uq_cols
    UNION ALL
    SELECT table_name, column_name, constraint_type FROM _fk_cols
),
columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.ordinal_position,
        c.is_nullable,
        c.data_type,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
)
SELECT
    c.table_catalog AS database_name,
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
        ELSE 'NONE'
    END AS constraint_status,
    CASE
        WHEN kc.constraint_type IS NOT NULL THEN 'Has key constraint'
        WHEN c.is_nullable = 'NO' THEN 'Has NOT NULL constraint'
        ELSE 'Consider adding NOT NULL or key constraints for data quality'
    END AS recommendation
FROM columns_in_scope c
LEFT JOIN key_constraints kc
    ON UPPER(c.table_name) = UPPER(kc.table_name)
    AND UPPER(c.column_name) = UPPER(kc.column_name)
ORDER BY
    constraint_status = 'NONE' DESC,
    c.table_name,
    c.ordinal_position;

DROP TABLE IF EXISTS _pk_cols;
DROP TABLE IF EXISTS _uq_cols;
DROP TABLE IF EXISTS _fk_cols;
```
