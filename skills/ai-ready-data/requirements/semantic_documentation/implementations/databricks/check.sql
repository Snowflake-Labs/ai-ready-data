WITH column_stats AS (
    SELECT
        COUNT(*) AS total_columns,
        SUM(CASE WHEN c.comment IS NOT NULL AND c.comment != '' THEN 1 ELSE 0 END) AS commented_columns
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name = t.table_name
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
)
SELECT
    commented_columns,
    total_columns,
    CAST(commented_columns AS DOUBLE) / NULLIF(CAST(total_columns AS DOUBLE), 0) AS value
FROM column_stats
