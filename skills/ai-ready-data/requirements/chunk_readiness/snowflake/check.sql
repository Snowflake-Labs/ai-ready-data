-- check-chunk-readiness.sql
-- Checks if text content is appropriately sized for embedding models
-- Returns: value (float 0-1) - fraction of text within optimal chunk size

-- Optimal range is 100-8000 chars (~25-2000 tokens).
-- Shorter text may lack semantic content; longer text should be chunked
-- with overlap for better retrieval precision.

WITH text_stats AS (
    SELECT
        '{{ text_column }}' AS column_name,
        COUNT(*) AS total_rows,
        COUNT_IF(LENGTH({{ text_column }}) BETWEEN 100 AND 8000) AS optimal_length_rows,
        COUNT_IF(LENGTH({{ text_column }}) < 100) AS too_short_rows,
        COUNT_IF(LENGTH({{ text_column }}) > 8000) AS too_long_rows,
        AVG(LENGTH({{ text_column }})) AS avg_length,
        MEDIAN(LENGTH({{ text_column }})) AS median_length
    FROM {{ database }}.{{ schema }}.{{ asset }}
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
