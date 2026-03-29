-- check-data-version-coverage.sql
-- Checks fraction of tables with Time Travel enabled (version history)
-- Returns: value (float 0-1) - fraction of tables with version coverage

WITH tables_in_scope AS (
    SELECT
        table_name,
        retention_time
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_versioning AS (
    SELECT * FROM tables_in_scope
    WHERE retention_time > 0
)
SELECT
    (SELECT COUNT(*) FROM tables_with_versioning) AS tables_with_versioning,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_versioning)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
