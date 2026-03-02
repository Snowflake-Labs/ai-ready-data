WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tested_tables AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM snowflake.account_usage.tag_references
    WHERE object_database = '{{ database }}'
        AND object_schema = '{{ schema }}'
        AND domain = 'TABLE'
        AND LOWER(tag_name) IN ('bias_tested', 'bias_test_date', 'fairness_tested', 'bias_status')
)
SELECT
    tested_tables.cnt AS tables_bias_tested,
    table_count.cnt AS total_tables,
    tested_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tested_tables
