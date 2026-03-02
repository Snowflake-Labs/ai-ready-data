SELECT
    t.table_name,
    t.row_count,
    t.retention_time AS time_travel_days,
    tr.tag_name AS retention_tag,
    tr.tag_value AS retention_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'HAS_RETENTION_POLICY'
        ELSE 'NO_RETENTION_POLICY'
    END AS status
FROM {{ container }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON tr.object_database = '{{ container }}'
    AND tr.object_schema = '{{ namespace }}'
    AND tr.object_name = t.table_name
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('retention_days', 'retention_policy', 'data_retention', 'ttl')
WHERE t.table_schema = '{{ namespace }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
