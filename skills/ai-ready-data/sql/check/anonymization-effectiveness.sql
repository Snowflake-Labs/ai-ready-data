WITH pii_columns AS (
    SELECT c.table_name, c.column_name
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND (
            LOWER(c.column_name) LIKE '%email%'
            OR LOWER(c.column_name) LIKE '%phone%'
            OR LOWER(c.column_name) LIKE '%ssn%'
            OR LOWER(c.column_name) LIKE '%name%'
            OR LOWER(c.column_name) LIKE '%address%'
        )
),
protected_columns AS (
    SELECT DISTINCT ref_entity_name AS table_name, ref_column_name AS column_name
    FROM snowflake.account_usage.policy_references
    WHERE ref_database_name = '{{ database }}'
        AND ref_schema_name = '{{ schema }}'
        AND policy_kind = 'MASKING_POLICY'
    UNION
    SELECT DISTINCT object_name AS table_name, column_name
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ database }}'
        AND object_schema = '{{ schema }}'
        AND domain = 'COLUMN'
        AND LOWER(tag_name) IN ('pii', 'sensitive', 'anonymized', 'privacy_category')
)
SELECT
    COUNT(*) AS total_pii_columns,
    COUNT(p.column_name) AS protected_pii_columns,
    COUNT(p.column_name)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM pii_columns pc
LEFT JOIN protected_columns p
    ON pc.table_name = p.table_name AND pc.column_name = p.column_name
