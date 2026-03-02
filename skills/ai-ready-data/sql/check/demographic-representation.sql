WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
documented_tables AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ database }}'
        AND object_schema = '{{ schema }}'
        AND domain IN ('TABLE', 'COLUMN')
        AND LOWER(tag_name) IN ('demographic', 'protected_class', 'sensitive_attribute', 'fairness_attribute')
)
SELECT
    documented_tables.cnt AS tables_with_demographics,
    table_count.cnt AS total_tables,
    documented_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, documented_tables
