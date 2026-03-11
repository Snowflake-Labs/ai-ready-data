-- check-feature-materialization-coverage.sql
-- Checks fraction of features available in materialized views or dynamic tables
-- Returns: value (float 0-1) - fraction of tables with materialization

WITH tables_in_scope AS (
    SELECT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
materialized_tables AS (
    SELECT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('DYNAMIC TABLE', 'MATERIALIZED VIEW')
)
SELECT
    (SELECT COUNT(*) FROM materialized_tables) AS materialized_count,
    (SELECT COUNT(*) FROM tables_in_scope) + (SELECT COUNT(*) FROM materialized_tables) AS total_count,
    (SELECT COUNT(*) FROM materialized_tables)::FLOAT / 
        NULLIF(((SELECT COUNT(*) FROM tables_in_scope) + (SELECT COUNT(*) FROM materialized_tables))::FLOAT, 0) AS value
