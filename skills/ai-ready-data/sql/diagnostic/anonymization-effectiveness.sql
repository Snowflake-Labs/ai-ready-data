WITH pii_columns AS (
    SELECT c.table_name, c.column_name, c.data_type
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
masked AS (
    SELECT DISTINCT ref_entity_name AS table_name, ref_column_name AS column_name, 'MASKING_POLICY' AS protection
    FROM snowflake.account_usage.policy_references
    WHERE ref_database_name = '{{ database }}'
        AND ref_schema_name = '{{ schema }}'
        AND policy_kind = 'MASKING_POLICY'
),
tagged AS (
    SELECT DISTINCT object_name AS table_name, column_name, 'TAG:' || tag_name AS protection
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ database }}'
        AND object_schema = '{{ schema }}'
        AND domain = 'COLUMN'
        AND LOWER(tag_name) IN ('pii', 'sensitive', 'anonymized', 'privacy_category')
)
SELECT
    pc.table_name,
    pc.column_name,
    pc.data_type,
    COALESCE(m.protection, t.protection, 'UNPROTECTED') AS protection_status
FROM pii_columns pc
LEFT JOIN masked m ON pc.table_name = m.table_name AND pc.column_name = m.column_name
LEFT JOIN tagged t ON pc.table_name = t.table_name AND pc.column_name = t.column_name
ORDER BY protection_status, pc.table_name, pc.column_name
