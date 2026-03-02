WITH pii_columns AS (
    SELECT c.table_name, c.column_name
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
masked_columns AS (
    SELECT DISTINCT ref_entity_name AS table_name, ref_column_name AS column_name
    FROM snowflake.account_usage.policy_references
    WHERE ref_database_name = '{{ container }}'
        AND ref_schema_name = '{{ namespace }}'
        AND policy_kind = 'MASKING_POLICY'
),
coverage AS (
    SELECT
        COUNT(*) AS pii_count,
        COUNT(m.column_name) AS masked_count
    FROM pii_columns p
    LEFT JOIN masked_columns m
        ON p.table_name = m.table_name AND p.column_name = m.column_name
)
SELECT
    masked_count AS masked_pii_columns,
    pii_count AS total_pii_columns,
    masked_count::FLOAT / NULLIF(pii_count::FLOAT, 0) AS value
FROM coverage
