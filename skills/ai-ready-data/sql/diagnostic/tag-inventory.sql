SELECT
    t.table_name,
    COALESCE(tr.tag_name, '(no tags)') AS tag_name,
    tr.tag_value
FROM {{ container }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON t.table_name = tr.object_name
    AND t.table_schema = tr.object_schema
    AND tr.domain = 'TABLE'
    AND tr.object_database = '{{ container }}'
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, tr.tag_name
