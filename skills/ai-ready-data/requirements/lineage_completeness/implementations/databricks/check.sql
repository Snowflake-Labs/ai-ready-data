-- Uses Unity Catalog lineage system table.
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
      AND table_type = 'BASE TABLE'
),
tables_with_lineage AS (
    SELECT DISTINCT target_table_name AS table_name
    FROM system.access.table_lineage
    WHERE target_table_catalog = '{{ database }}'
      AND target_table_schema = '{{ schema }}'
      AND event_time >= CURRENT_TIMESTAMP() - INTERVAL 30 DAYS
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t
      WHERE UPPER(t.table_name) IN (SELECT UPPER(table_name) FROM tables_with_lineage)
    ) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    CAST((SELECT COUNT(*) FROM tables_in_scope t
      WHERE UPPER(t.table_name) IN (SELECT UPPER(table_name) FROM tables_with_lineage)
    ) AS DOUBLE) / NULLIF(CAST((SELECT COUNT(*) FROM tables_in_scope) AS DOUBLE), 0) AS value
