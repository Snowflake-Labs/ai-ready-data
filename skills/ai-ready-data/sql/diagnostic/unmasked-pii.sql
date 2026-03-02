WITH pii_columns AS (
    SELECT c.table_name, c.column_name, c.data_type
    FROM {{ container }}.information_schema.columns c
    JOIN {{ container }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ namespace }}'
        AND t.table_type = 'BASE TABLE'
        AND (
            LOWER(c.column_name) LIKE '%email%'
            OR LOWER(c.column_name) LIKE '%phone%'
            OR LOWER(c.column_name) LIKE '%ssn%'
            OR LOWER(c.column_name) LIKE '%password%'
            OR LOWER(c.column_name) LIKE '%credit_card%'
            OR LOWER(c.column_name) LIKE '%address%'
        )
),
masked AS (
    SELECT ref_entity_name AS table_name, ref_column_name AS column_name
    FROM snowflake.account_usage.policy_references
    WHERE ref_database_name = '{{ container }}'
        AND ref_schema_name = '{{ namespace }}'
        AND policy_kind = 'MASKING_POLICY'
)
SELECT p.table_name, p.column_name, p.data_type, 'NEEDS MASKING' AS status
FROM pii_columns p
LEFT JOIN masked m
    ON p.table_name = m.table_name AND p.column_name = m.column_name
WHERE m.column_name IS NULL
ORDER BY p.table_name, p.column_name
