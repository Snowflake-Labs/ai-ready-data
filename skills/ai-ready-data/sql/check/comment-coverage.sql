WITH column_stats AS (
    SELECT
        COUNT(*) AS total_columns,
        COUNT_IF(comment IS NOT NULL AND comment != '') AS commented_columns
    FROM {{ container }}.information_schema.columns
    WHERE table_schema = '{{ namespace }}'
)
SELECT
    commented_columns,
    total_columns,
    commented_columns::FLOAT / NULLIF(total_columns::FLOAT, 0) AS value
FROM column_stats
