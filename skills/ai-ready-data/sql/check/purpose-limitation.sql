WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
purpose_tagged AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ database }}'
        AND object_schema = '{{ schema }}'
        AND domain = 'TABLE'
        AND LOWER(tag_name) IN ('purpose', 'allowed_purpose', 'processing_purpose', 'data_purpose')
)
SELECT
    purpose_tagged.cnt AS tables_with_purpose,
    table_count.cnt AS total_tables,
    purpose_tagged.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, purpose_tagged
