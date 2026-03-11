SELECT
    t.table_name,
    COALESCE(tt.tag_name, '(no tags)') AS tag_name,
    tt.tag_value
FROM {{ database }}.information_schema.tables t
LEFT JOIN {{ database }}.information_schema.table_tags tt
    ON t.table_schema = tt.schema_name
   AND t.table_name = tt.table_name
WHERE t.table_schema = '{{ schema }}'
  AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, tt.tag_name
