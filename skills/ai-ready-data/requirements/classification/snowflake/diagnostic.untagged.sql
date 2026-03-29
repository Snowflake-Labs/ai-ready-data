SELECT t.table_name
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(t.table_name) = UPPER(tr.object_name)
    AND UPPER(t.table_schema) = UPPER(tr.object_schema)
    AND tr.domain = 'TABLE'
    AND UPPER(tr.object_database) = UPPER('{{ database }}')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND tr.object_name IS NULL
ORDER BY t.table_name
