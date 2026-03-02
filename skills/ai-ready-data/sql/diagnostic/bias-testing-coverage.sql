SELECT
    t.table_name,
    t.row_count,
    tr.tag_name AS bias_tag,
    tr.tag_value AS bias_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'TESTED'
        ELSE 'NOT_TESTED'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON tr.object_database = '{{ database }}'
    AND tr.object_schema = '{{ schema }}'
    AND tr.object_name = t.table_name
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('bias_tested', 'bias_test_date', 'fairness_tested', 'bias_status')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
