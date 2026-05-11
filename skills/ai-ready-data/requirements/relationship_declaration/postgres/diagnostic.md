# Diagnostic: relationship_declaration

Lists FK-candidate columns and their foreign key constraint status.

## Context

Identifies columns that appear to reference other entities based on naming patterns (`%_id` columns excluding primary keys) and reports whether each has an explicit foreign key constraint. For columns with declared FKs, shows the referenced table and column.

Columns with status `NO_FK` are implicit relationships — they likely reference another table but have no declared or enforced constraint. These are the primary remediation targets.

## SQL

```sql
WITH pk_columns AS (
    SELECT
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM information_schema.key_column_usage kcu
    INNER JOIN information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    WHERE kcu.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'PRIMARY KEY'
),
fk_candidate_columns AS (
    SELECT
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type
    FROM information_schema.columns c
    INNER JOIN information_schema.tables t
        ON c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND LOWER(c.column_name) LIKE '%\_id' ESCAPE '\'
        AND NOT EXISTS (
            SELECT 1 FROM pk_columns pk
            WHERE pk.table_schema = c.table_schema
              AND pk.table_name = c.table_name
              AND pk.column_name = c.column_name
        )
),
fk_details AS (
    SELECT
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name,
        tc.constraint_name,
        ccu.table_name AS referenced_table,
        ccu.column_name AS referenced_column
    FROM information_schema.key_column_usage kcu
    INNER JOIN information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    INNER JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
        AND tc.table_schema = ccu.table_schema
    WHERE kcu.table_schema = '{{ schema }}'
        AND tc.constraint_type = 'FOREIGN KEY'
)
SELECT
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type,
    COALESCE(fk.constraint_name, 'NONE') AS fk_constraint,
    COALESCE(fk.referenced_table, '') AS referenced_table,
    COALESCE(fk.referenced_column, '') AS referenced_column,
    CASE
        WHEN fk.constraint_name IS NOT NULL THEN 'HAS_FK'
        ELSE 'NO_FK'
    END AS relationship_status
FROM fk_candidate_columns c
LEFT JOIN fk_details fk
    ON c.table_schema = fk.table_schema
    AND c.table_name = fk.table_name
    AND c.column_name = fk.column_name
ORDER BY
    relationship_status DESC,
    c.table_name,
    c.column_name
```
