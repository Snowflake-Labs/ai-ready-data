-- check-business-glossary-linkage.sql
-- Checks fraction of columns linked to business glossary terms via tags or comments
-- Returns: value (float 0-1) - fraction of columns with glossary evidence

-- Business glossary linkage in Snowflake is typically done via:
-- 1. Object tags (TAG_REFERENCES view) — primary signal
-- 2. Column comments with meaningful descriptions — secondary signal

WITH columns_in_scope AS (
    SELECT
        c.table_name,
        c.column_name,
        c.comment
    FROM {{ database }}.information_schema.columns c
    INNER JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
),
tagged_columns AS (
    SELECT DISTINCT
        UPPER(object_name) AS table_name,
        UPPER(column_name) AS column_name
    FROM snowflake.account_usage.tag_references
    WHERE UPPER(object_database) = UPPER('{{ database }}')
        AND UPPER(object_schema) = UPPER('{{ schema }}')
        AND domain = 'COLUMN'
)
SELECT
    COUNT_IF(
        tc.column_name IS NOT NULL
        OR (c.comment IS NOT NULL AND LENGTH(c.comment) > 20)
    ) AS columns_with_glossary,
    COUNT(*) AS total_columns,
    COUNT_IF(
        tc.column_name IS NOT NULL
        OR (c.comment IS NOT NULL AND LENGTH(c.comment) > 20)
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM columns_in_scope c
LEFT JOIN tagged_columns tc
    ON UPPER(c.table_name) = tc.table_name
    AND UPPER(c.column_name) = tc.column_name
