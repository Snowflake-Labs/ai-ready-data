WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
consent_tagged AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ database }}'
        AND object_schema = '{{ schema }}'
        AND domain = 'TABLE'
        AND LOWER(tag_name) IN ('consent_basis', 'legal_basis', 'processing_basis', 'consent')
)
SELECT
    consent_tagged.cnt AS tables_with_consent,
    table_count.cnt AS total_tables,
    consent_tagged.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, consent_tagged
