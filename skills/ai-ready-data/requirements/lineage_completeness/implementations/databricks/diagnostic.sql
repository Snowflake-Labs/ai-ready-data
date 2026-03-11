SELECT
    target_table_catalog,
    target_table_schema,
    target_table_name,
    source_table_catalog,
    source_table_schema,
    source_table_name,
    created_by AS modified_by,
    event_time
FROM system.access.table_lineage
WHERE target_table_catalog = '{{ database }}'
  AND target_table_schema = '{{ schema }}'
  AND event_time >= CURRENT_TIMESTAMP() - INTERVAL 30 DAYS
ORDER BY event_time DESC
LIMIT 100
