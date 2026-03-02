SELECT
    t.table_name,
    t.row_count,
    tr.tag_name AS consent_tag,
    tr.tag_value AS consent_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_CONSENT_BASIS'
        ELSE 'NO_CONSENT_BASIS'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON tr.object_database = '{{ database }}'
    AND tr.object_schema = '{{ schema }}'
    AND tr.object_name = t.table_name
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('consent_basis', 'legal_basis', 'processing_basis', 'consent')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
