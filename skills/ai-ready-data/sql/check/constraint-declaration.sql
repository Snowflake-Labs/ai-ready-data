-- check-constraint-declaration.sql
-- Checks fraction of columns with explicitly declared constraints
-- Returns: value (float 0-1) - fraction of columns with constraints

WITH columns_in_scope AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.is_nullable,
        c.data_type,
        c.character_maximum_length,
        c.numeric_precision,
        c.numeric_scale
    FROM {{ container }}.information_schema.columns c
    INNER JOIN {{ container }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
),
-- Get columns involved in constraints
constrained_columns AS (
    SELECT DISTINCT
        kcu.table_catalog,
        kcu.table_schema,
        kcu.table_name,
        kcu.column_name
    FROM {{ container }}.information_schema.key_column_usage kcu
    WHERE kcu.table_schema = '{{ namespace }}'
),
columns_with_constraints AS (
    SELECT c.*
    FROM columns_in_scope c
    WHERE
        -- NOT NULL is a constraint
        c.is_nullable = 'NO'
        -- Part of a key constraint (PK, FK, UNIQUE)
        OR EXISTS (
            SELECT 1 FROM constrained_columns cc
            WHERE c.table_catalog = cc.table_catalog
              AND c.table_schema = cc.table_schema
              AND c.table_name = cc.table_name
              AND c.column_name = cc.column_name
        )
        -- Has length constraint
        OR c.character_maximum_length IS NOT NULL
        -- Has precision/scale constraint
        OR (c.numeric_precision IS NOT NULL AND c.numeric_scale IS NOT NULL)
)
SELECT
    (SELECT COUNT(*) FROM columns_with_constraints) AS columns_with_constraints,
    (SELECT COUNT(*) FROM columns_in_scope) AS total_columns,
    (SELECT COUNT(*) FROM columns_with_constraints)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM columns_in_scope)::FLOAT, 0) AS value
