-- diagnostic-embedding-coverage.sql
-- Lists tables with text content and their embedding status
-- Returns: tables with text columns and whether they have vector columns

WITH text_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name AS text_column,
        c.character_maximum_length AS max_length
    FROM {{ container }}.information_schema.columns c
    INNER JOIN {{ container }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('VARCHAR', 'TEXT', 'STRING')
        AND (
            LOWER(c.column_name) LIKE '%text%'
            OR LOWER(c.column_name) LIKE '%content%'
            OR LOWER(c.column_name) LIKE '%description%'
            OR LOWER(c.column_name) LIKE '%body%'
            OR LOWER(c.column_name) LIKE '%message%'
            OR LOWER(c.column_name) LIKE '%comment%'
            OR LOWER(c.column_name) LIKE '%review%'
            OR LOWER(c.column_name) LIKE '%summary%'
            OR LOWER(c.column_name) LIKE '%abstract%'
            OR LOWER(c.column_name) LIKE '%document%'
            OR LOWER(c.column_name) LIKE '%article%'
            OR LOWER(c.column_name) LIKE '%note%'
        )
),
vector_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name AS vector_column,
        c.comment AS vector_comment
    FROM {{ container }}.information_schema.columns c
    WHERE c.table_schema = '{{ namespace }}'
        AND c.data_type = 'VECTOR'
)
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.text_column,
    t.max_length AS text_max_length,
    COALESCE(v.vector_column, 'NONE') AS vector_column,
    CASE
        WHEN v.vector_column IS NOT NULL THEN 'HAS_EMBEDDING'
        ELSE 'NO_EMBEDDING'
    END AS embedding_status,
    CASE
        WHEN v.vector_column IS NOT NULL THEN 'Embedding available'
        ELSE 'Consider adding vector column with SNOWFLAKE.CORTEX.EMBED_TEXT_768 or EMBED_TEXT_1024'
    END AS recommendation
FROM text_columns t
LEFT JOIN vector_columns v
    ON t.table_catalog = v.table_catalog
    AND t.table_schema = v.table_schema
    AND t.table_name = v.table_name
ORDER BY embedding_status DESC, t.table_name, t.text_column
