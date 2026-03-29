# Diagnostic: entity_identifier_declaration

Per-table breakdown of primary key and unique constraint status.

## Context

Lists each base table with its identifier constraint name, type (PRIMARY KEY, UNIQUE, or MISSING), and an overall status. Tables with status `NO_IDENTIFIER` have neither a primary key nor a unique constraint declared.

Primary key constraints in Snowflake are not enforced — they are metadata hints. A table showing `HAS_UNIQUE_ONLY` has a unique constraint but no primary key, which may still be sufficient depending on modeling conventions.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        t.table_catalog,
        t.table_schema,
        t.table_name,
        t.row_count
    FROM {{ database }}.information_schema.tables t
    WHERE t.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
pk_constraints AS (
    SELECT 
        tc.table_catalog,
        tc.table_schema,
        tc.table_name,
        tc.constraint_name,
        'PRIMARY KEY' AS constraint_type
    FROM {{ database }}.information_schema.table_constraints tc
    WHERE tc.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'PRIMARY KEY'
),
unique_constraints AS (
    SELECT 
        tc.table_catalog,
        tc.table_schema,
        tc.table_name,
        tc.constraint_name,
        'UNIQUE' AS constraint_type
    FROM {{ database }}.information_schema.table_constraints tc
    WHERE tc.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'UNIQUE'
)
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.row_count,
    COALESCE(pk.constraint_name, uq.constraint_name, 'NONE') AS identifier_constraint,
    COALESCE(pk.constraint_type, uq.constraint_type, 'MISSING') AS identifier_type,
    CASE
        WHEN pk.table_name IS NOT NULL THEN 'HAS_PRIMARY_KEY'
        WHEN uq.table_name IS NOT NULL THEN 'HAS_UNIQUE_ONLY'
        ELSE 'NO_IDENTIFIER'
    END AS identifier_status
FROM tables_in_scope t
LEFT JOIN pk_constraints pk 
    ON t.table_catalog = pk.table_catalog 
    AND t.table_schema = pk.table_schema 
    AND t.table_name = pk.table_name
LEFT JOIN unique_constraints uq 
    ON t.table_catalog = uq.table_catalog 
    AND t.table_schema = uq.table_schema 
    AND t.table_name = uq.table_name
ORDER BY 
    identifier_status DESC,
    t.table_name
```
