SELECT t.table_name
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON t.table_name = tr.object_name
    AND t.table_schema = tr.object_schema
    AND tr.domain = 'TABLE'
    AND tr.object_database = '{{ database }}'
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND tr.object_name IS NULL
ORDER BY t.table_name
