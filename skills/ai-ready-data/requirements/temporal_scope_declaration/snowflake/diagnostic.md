# Diagnostic: temporal_scope_declaration

Per-column breakdown of temporal column documentation status with suggested temporal roles.

## Context

Lists every date/timestamp column in the schema along with its documentation status (`DOCUMENTED` or `UNDOCUMENTED`) and a suggested temporal role inferred from column name patterns (e.g., `created_at` → `CREATION_TIMESTAMP`, `effective_date` → `EFFECTIVE_DATE`). Columns that don't match any known pattern are labeled `UNKNOWN_ROLE`.

Use this to identify which temporal columns need comments and what role each likely serves.

## SQL

```sql
SELECT
    c.table_catalog AS database_name,
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type AS temporal_type,
    c.is_nullable,
    CASE
        WHEN c.comment IS NOT NULL AND c.comment != '' THEN 'DOCUMENTED'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    COALESCE(c.comment, '') AS current_comment,
    -- Suggest temporal role based on column name patterns
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
FROM {{ database }}.information_schema.columns c
WHERE c.table_schema = '{{ schema }}'
    AND c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ', 'TIME')
ORDER BY 
    documentation_status DESC,
    c.table_name,
    c.ordinal_position
```
