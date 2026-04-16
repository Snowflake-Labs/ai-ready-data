# Diagnostic: temporal_scope_declaration

Per-column breakdown of temporal column documentation status with suggested temporal roles.

## Context

Lists every date/timestamp column in the schema (by data type or temporal name pattern) along with its documentation status (`DOCUMENTED` or `UNDOCUMENTED`) and a suggested temporal role inferred from column name patterns (e.g., `created_at` -> `CREATION_TIMESTAMP`, `effective_date` -> `EFFECTIVE_DATE`). Columns that don't match any known pattern are labeled `UNKNOWN_ROLE`.

PostgreSQL column comments are retrieved via `col_description()` from `pg_catalog`. Use this to identify which temporal columns need comments and what role each likely serves.

## SQL

```sql
SELECT
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type AS temporal_type,
    c.is_nullable,
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
    ) AS current_comment,
    CASE
        WHEN LOWER(c.column_name) LIKE '%created%' THEN 'CREATION_TIMESTAMP'
        WHEN LOWER(c.column_name) LIKE '%updated%' THEN 'UPDATE_TIMESTAMP'
        WHEN LOWER(c.column_name) LIKE '%modified%' THEN 'UPDATE_TIMESTAMP'
        WHEN LOWER(c.column_name) LIKE '%deleted%' THEN 'SOFT_DELETE_TIMESTAMP'
        WHEN LOWER(c.column_name) LIKE '%start%' THEN 'VALIDITY_START'
        WHEN LOWER(c.column_name) LIKE '%end%' THEN 'VALIDITY_END'
        WHEN LOWER(c.column_name) LIKE '%effective%' THEN 'EFFECTIVE_DATE'
        WHEN LOWER(c.column_name) LIKE '%expire%' THEN 'EXPIRATION_DATE'
        WHEN LOWER(c.column_name) LIKE '%event%' THEN 'EVENT_TIMESTAMP'
        WHEN LOWER(c.column_name) LIKE '%transaction%' THEN 'TRANSACTION_TIMESTAMP'
        ELSE 'UNKNOWN_ROLE'
    END AS suggested_temporal_role
FROM information_schema.columns c
INNER JOIN information_schema.tables t
    ON c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND (
        c.data_type IN ('date', 'timestamp without time zone', 'timestamp with time zone',
                        'time without time zone', 'time with time zone')
        OR LOWER(c.column_name) LIKE '%\_at' ESCAPE '\'
        OR LOWER(c.column_name) LIKE '%\_date' ESCAPE '\'
        OR LOWER(c.column_name) LIKE '%valid%'
        OR LOWER(c.column_name) LIKE '%effective%'
    )
ORDER BY
    documentation_status DESC,
    c.table_name,
    c.ordinal_position
```
