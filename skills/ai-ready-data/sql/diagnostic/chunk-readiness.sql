-- diagnostic-chunk-readiness.sql
-- Analyzes text content length distribution for chunking decisions
-- Returns: length distribution with recommendations

WITH length_buckets AS (
    SELECT
        CASE
            WHEN LENGTH({{ text_column }}) IS NULL THEN 'NULL'
            WHEN LENGTH({{ text_column }}) = 0 THEN 'EMPTY'
            WHEN LENGTH({{ text_column }}) < 100 THEN 'TOO_SHORT (<100)'
            WHEN LENGTH({{ text_column }}) BETWEEN 100 AND 500 THEN 'SHORT (100-500)'
            WHEN LENGTH({{ text_column }}) BETWEEN 501 AND 2000 THEN 'OPTIMAL (501-2000)'
            WHEN LENGTH({{ text_column }}) BETWEEN 2001 AND 8000 THEN 'GOOD (2001-8000)'
            WHEN LENGTH({{ text_column }}) BETWEEN 8001 AND 32000 THEN 'LONG (8001-32000)'
            ELSE 'TOO_LONG (>32000)'
        END AS length_bucket,
        COUNT(*) AS row_count
    FROM {{ database }}.{{ schema }}.{{ asset }}
    GROUP BY 1
)
SELECT
    length_bucket,
    row_count,
    ROUND(row_count * 100.0 / SUM(row_count) OVER (), 2) AS percentage,
    CASE
        WHEN length_bucket = 'NULL' THEN 'Missing content - exclude or impute'
        WHEN length_bucket = 'EMPTY' THEN 'Empty strings - exclude from embedding'
        WHEN length_bucket = 'TOO_SHORT (<100)' THEN 'May lack semantic content - consider combining with context'
        WHEN length_bucket IN ('SHORT (100-500)', 'OPTIMAL (501-2000)', 'GOOD (2001-8000)') THEN 'Good for embedding - no chunking needed'
        WHEN length_bucket = 'LONG (8001-32000)' THEN 'Consider chunking with overlap for better retrieval'
        WHEN length_bucket = 'TOO_LONG (>32000)' THEN 'Must chunk - exceeds most model context windows'
        ELSE 'Review manually'
    END AS recommendation
FROM length_buckets
ORDER BY 
    CASE length_bucket
        WHEN 'NULL' THEN 1
        WHEN 'EMPTY' THEN 2
        WHEN 'TOO_SHORT (<100)' THEN 3
        WHEN 'SHORT (100-500)' THEN 4
        WHEN 'OPTIMAL (501-2000)' THEN 5
        WHEN 'GOOD (2001-8000)' THEN 6
        WHEN 'LONG (8001-32000)' THEN 7
        WHEN 'TOO_LONG (>32000)' THEN 8
    END
