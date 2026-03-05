WITH column_stats AS (
    SELECT
        COUNT(*) AS total_columns,
        COUNT_IF(c.comment IS NOT NULL AND c.comment != '') AS commented_columns
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
    commented_columns::FLOAT / NULLIF(total_columns::FLOAT, 0) AS value
FROM column_stats
