-- check-embedding-coverage.sql
-- Checks fraction of text columns that have corresponding vector embeddings
-- Returns: value (float 0-1) - fraction of text assets with embeddings

WITH text_columns AS (
    -- Find columns likely to need embeddings (text content columns)
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name
    FROM {{ container }}.information_schema.columns c
    INNER JOIN {{ container }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('VARCHAR', 'TEXT', 'STRING')
        -- Filter to likely content columns (not IDs, codes, etc.)
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
    -- Find VECTOR type columns
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name
    FROM {{ container }}.information_schema.columns c
    WHERE c.table_schema = '{{ namespace }}'
        AND c.data_type = 'VECTOR'
),
tables_with_text AS (
    SELECT DISTINCT table_name FROM text_columns
),
tables_with_vectors AS (
    SELECT DISTINCT table_name FROM vector_columns
)
SELECT
    (SELECT COUNT(*) FROM tables_with_vectors) AS tables_with_embeddings,
    (SELECT COUNT(*) FROM tables_with_text) AS tables_with_text_content,
    CASE 
        WHEN (SELECT COUNT(*) FROM tables_with_text) = 0 THEN 1.0
        ELSE (SELECT COUNT(*) FROM tables_with_vectors)::FLOAT / 
             (SELECT COUNT(*) FROM tables_with_text)::FLOAT
    END AS value
