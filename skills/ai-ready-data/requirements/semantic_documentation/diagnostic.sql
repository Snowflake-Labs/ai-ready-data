SELECT t.table_name
FROM {{ database }}.information_schema.tables t
LEFT JOIN {{ database }}.information_schema.semantic_tables st
    ON t.table_name = st.base_table_name
    AND t.table_schema = st.base_table_schema
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND st.base_table_name IS NULL
ORDER BY t.table_name
