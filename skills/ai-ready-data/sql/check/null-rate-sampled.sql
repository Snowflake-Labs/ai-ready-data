SELECT
    '{{ asset }}' AS table_name,
    '{{ field }}' AS column_name,
    COUNT_IF({{ field }} IS NULL) * 1.0 / NULLIF(COUNT(*), 0) AS value
FROM {{ container }}.{{ namespace }}.{{ asset }}
    TABLESAMPLE ({{ sample_rows }} ROWS)
