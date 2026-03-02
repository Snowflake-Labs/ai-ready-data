WITH large_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
        AND row_count > 10000
),
clustered AS (
    SELECT COUNT(*) AS cnt
    FROM {{ container }}.information_schema.tables
    WHERE table_schema = '{{ namespace }}'
        AND table_type = 'BASE TABLE'
        AND row_count > 10000
        AND clustering_key IS NOT NULL
)
SELECT
    clustered.cnt AS clustered_tables,
    large_tables.cnt AS large_tables,
    clustered.cnt::FLOAT / NULLIF(large_tables.cnt::FLOAT, 0) AS value
FROM large_tables, clustered
