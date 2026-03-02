-- check-chunk-readiness.sql
-- Checks if text content is appropriately chunked for embedding models
-- Returns: value (float 0-1) - fraction of text within optimal chunk size

-- Optimal chunk sizes for common embedding models:
-- - 512 tokens (~2000 chars) for smaller models
-- - 8192 tokens (~32000 chars) for larger models like e5-large
-- We check if text is within reasonable bounds (not too short, not too long)

WITH text_stats AS (
    SELECT
        '{{ text_column }}' AS column_name,
        COUNT(*) AS total_rows,
        COUNT_IF(LENGTH({{ text_column }}) BETWEEN 100 AND 8000) AS optimal_length_rows,
        COUNT_IF(LENGTH({{ text_column }}) < 100) AS too_short_rows,
        COUNT_IF(LENGTH({{ text_column }}) > 8000) AS too_long_rows,
        AVG(LENGTH({{ text_column }})) AS avg_length,
        MEDIAN(LENGTH({{ text_column }})) AS median_length
    FROM {{ container }}.{{ namespace }}.{{ asset }}
    WHERE {{ text_column }} IS NOT NULL
)
SELECT
    column_name,
    total_rows,
    optimal_length_rows,
    too_short_rows,
    too_long_rows,
    ROUND(avg_length, 0) AS avg_char_length,
    ROUND(median_length, 0) AS median_char_length,
    optimal_length_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM text_stats
