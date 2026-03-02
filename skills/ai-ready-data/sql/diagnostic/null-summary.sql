SELECT
    c.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable
FROM {{ container }}.information_schema.columns c
JOIN {{ container }}.information_schema.tables t
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE c.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY c.table_name, c.ordinal_position
