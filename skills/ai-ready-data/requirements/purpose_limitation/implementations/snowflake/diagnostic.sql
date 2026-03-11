SELECT
    t.table_name,
    t.row_count,
    tr.tag_name AS purpose_tag,
    tr.tag_value AS purpose_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_PURPOSE_TAG'
        ELSE 'NO_PURPOSE_TAG'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('purpose', 'allowed_purpose', 'processing_purpose', 'data_purpose')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
