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
            OR LOWER(c.column_name) LIKE '%first_name%'
            OR LOWER(c.column_name) LIKE '%last_name%'
            OR LOWER(c.column_name) LIKE '%full_name%'
            OR LOWER(c.column_name) LIKE '%person_name%'
            OR LOWER(c.column_name) = 'name'
            OR LOWER(c.column_name) LIKE '%address%'
        )
),
masked AS (
    SELECT DISTINCT
        UPPER(ref_entity_name) AS table_name,
        UPPER(ref_column_name) AS column_name,
        'MASKING_POLICY' AS protection
    FROM snowflake.account_usage.policy_references
    WHERE UPPER(ref_database_name) = UPPER('{{ database }}')
        AND UPPER(ref_schema_name) = UPPER('{{ schema }}')
        AND policy_kind = 'MASKING_POLICY'
),
tagged AS (
    SELECT DISTINCT
        UPPER(object_name) AS table_name,
        UPPER(column_name) AS column_name,
        'TAG:' || tag_name AS protection
    FROM snowflake.account_usage.tag_references
    WHERE UPPER(object_database) = UPPER('{{ database }}')
        AND UPPER(object_schema) = UPPER('{{ schema }}')
        AND domain = 'COLUMN'
        AND LOWER(tag_name) IN ('pii', 'sensitive', 'anonymized', 'privacy_category')
)
SELECT
    pc.table_name,
    pc.column_name,
    pc.data_type,
    COALESCE(m.protection, t.protection, 'UNPROTECTED') AS protection_status
FROM pii_columns pc
LEFT JOIN masked m ON UPPER(pc.table_name) = m.table_name AND UPPER(pc.column_name) = m.column_name
LEFT JOIN tagged t ON UPPER(pc.table_name) = t.table_name AND UPPER(pc.column_name) = t.column_name
ORDER BY protection_status, pc.table_name, pc.column_name
