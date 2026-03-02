-- check-data-provenance.sql
-- Checks fraction of tables with documented source provenance (via comments or tags)
-- Returns: value (float 0-1) - fraction of tables with provenance documentation

WITH tables_in_scope AS (
    SELECT
        table_catalog,
        table_schema,
        table_name,
        comment
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
),
tables_with_provenance AS (
    SELECT *
    FROM tables_in_scope
    WHERE 
        comment IS NOT NULL 
        AND LENGTH(comment) > 20
        AND (
            LOWER(comment) LIKE '%source%'
            OR LOWER(comment) LIKE '%origin%'
            OR LOWER(comment) LIKE '%from%'
            OR LOWER(comment) LIKE '%upstream%'
            OR LOWER(comment) LIKE '%loaded%'
            OR LOWER(comment) LIKE '%extracted%'
        )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_provenance) AS tables_with_provenance,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_provenance)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
