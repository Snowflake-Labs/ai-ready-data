SELECT
    t.table_name,
    t.row_count,
    t.comment AS table_comment,
    tr.tag_name AS license_tag,
    tr.tag_value AS license_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_LICENSE'
        ELSE 'NO_LICENSE'
    END AS status
FROM {{ container }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON tr.object_database = '{{ container }}'
    AND tr.object_schema = '{{ namespace }}'
    AND tr.object_name = t.table_name
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('license', 'data_license', 'usage_license', 'license_type')
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
