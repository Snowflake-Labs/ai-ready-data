-- diagnostic-constraint-declaration.sql
-- Lists columns and their constraint status
-- Returns: columns with constraint details

WITH columns_in_scope AS (
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
),
key_constraints AS (
    SELECT
        kcu.table_catalog,
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name,
        tc.constraint_type
    FROM {{ database }}.information_schema.key_column_usage kcu
    INNER JOIN {{ database }}.information_schema.table_constraints tc
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    WHERE kcu.table_schema = '{{ schema }}'
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
        WHEN c.character_maximum_length IS NOT NULL THEN 'LENGTH'
        WHEN c.numeric_precision IS NOT NULL THEN 'PRECISION'
        ELSE 'NONE'
    END AS constraint_status,
    CASE
        WHEN kc.constraint_type IS NOT NULL THEN 'Has key constraint'
        WHEN c.is_nullable = 'NO' THEN 'Has NOT NULL constraint'
        WHEN c.character_maximum_length IS NOT NULL THEN 'Has length constraint'
        ELSE 'Consider adding constraints for data quality'
    END AS recommendation
FROM columns_in_scope c
LEFT JOIN key_constraints kc
    ON c.table_catalog = kc.table_catalog
    AND c.table_schema = kc.table_schema
    AND c.table_name = kc.table_name
    AND c.column_name = kc.column_name
ORDER BY 
    constraint_status = 'NONE' DESC,
    c.table_name,
    c.ordinal_position
