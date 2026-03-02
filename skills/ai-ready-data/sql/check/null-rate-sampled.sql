SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT_IF({{ column }} IS NULL) * 1.0 / NULLIF(COUNT(*), 0) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
    TABLESAMPLE ({{ sample_rows }} ROWS)
