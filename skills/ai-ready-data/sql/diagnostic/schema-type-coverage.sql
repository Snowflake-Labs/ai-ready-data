-- diagnostic-schema-type-coverage.sql
-- Lists columns and their inferred/declared semantic types
-- Returns: columns with semantic type analysis

SELECT
    c.table_catalog AS database_name,
    c.table_schema AS schema_name,
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    -- Infer semantic type from column name patterns
    CASE
        -- Identifiers / Keys
        WHEN LOWER(c.column_name) LIKE '%_id' OR LOWER(c.column_name) LIKE '%_key' THEN 'IDENTIFIER'
        WHEN LOWER(c.column_name) = 'id' OR LOWER(c.column_name) = 'key' THEN 'IDENTIFIER'
        
        -- Temporal
        WHEN c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ', 'TIME') THEN 'TEMPORAL'
        WHEN LOWER(c.column_name) LIKE '%_date' OR LOWER(c.column_name) LIKE '%_at' THEN 'TEMPORAL'
        
        -- Measures / Facts
        WHEN LOWER(c.column_name) LIKE '%amount%' OR LOWER(c.column_name) LIKE '%price%' THEN 'MEASURE'
        WHEN LOWER(c.column_name) LIKE '%cost%' OR LOWER(c.column_name) LIKE '%total%' THEN 'MEASURE'
        WHEN LOWER(c.column_name) LIKE '%count%' OR LOWER(c.column_name) LIKE '%quantity%' THEN 'MEASURE'
        WHEN LOWER(c.column_name) LIKE '%rate%' OR LOWER(c.column_name) LIKE '%percent%' THEN 'MEASURE'
        WHEN c.data_type IN ('NUMBER', 'DECIMAL', 'FLOAT', 'DOUBLE') AND c.is_nullable = 'YES' THEN 'LIKELY_MEASURE'
        
        -- Dimensions / Attributes
        WHEN LOWER(c.column_name) LIKE '%name' OR LOWER(c.column_name) LIKE '%description' THEN 'ATTRIBUTE'
        WHEN LOWER(c.column_name) LIKE '%status' OR LOWER(c.column_name) LIKE '%type' THEN 'CATEGORICAL'
        WHEN LOWER(c.column_name) LIKE '%category' OR LOWER(c.column_name) LIKE '%code' THEN 'CATEGORICAL'
        WHEN LOWER(c.column_name) LIKE '%flag' OR LOWER(c.column_name) LIKE '%is_%' THEN 'FLAG'
        WHEN c.data_type = 'BOOLEAN' THEN 'FLAG'
        
        -- Text content
        WHEN c.data_type IN ('VARCHAR', 'TEXT', 'STRING') AND 
             (LOWER(c.column_name) LIKE '%text%' OR LOWER(c.column_name) LIKE '%content%' OR 
              LOWER(c.column_name) LIKE '%body%' OR LOWER(c.column_name) LIKE '%message%') THEN 'TEXT_CONTENT'
        
        ELSE 'UNKNOWN'
    END AS inferred_semantic_type,
    CASE
        WHEN c.comment IS NOT NULL AND c.comment != '' THEN 'DOCUMENTED'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    COALESCE(c.comment, '') AS current_comment
FROM {{ container }}.information_schema.columns c
INNER JOIN {{ container }}.information_schema.tables t
    ON c.table_catalog = t.table_catalog
    AND c.table_schema = t.table_schema
    AND c.table_name = t.table_name
WHERE c.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY 
    c.table_name,
    c.ordinal_position
