# Check: chunk_readiness

Fraction of text content that falls within optimal chunk sizes for embedding models.

## Context

This is a table-scoped check on a specific text column. The optimal character range is 100–8,000 characters (~25–2,000 tokens). Text shorter than 100 characters may lack sufficient semantic content for meaningful embeddings. Text longer than 8,000 characters should be chunked with overlap for better retrieval precision.

The check also reports average and median character lengths to help characterize the distribution. If most content is far outside the optimal range, the diagnostic provides a detailed length distribution with per-bucket recommendations.

PostgreSQL uses `PERCENTILE_CONT` for median calculation rather than a native `MEDIAN` function.

## SQL

```sql
WITH text_stats AS (
    SELECT
        '{{ text_column }}' AS column_name,
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE LENGTH({{ text_column }}) BETWEEN 100 AND 8000) AS optimal_length_rows,
        COUNT(*) FILTER (WHERE LENGTH({{ text_column }}) < 100) AS too_short_rows,
        COUNT(*) FILTER (WHERE LENGTH({{ text_column }}) > 8000) AS too_long_rows,
        AVG(LENGTH({{ text_column }})) AS avg_length,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY LENGTH({{ text_column }})) AS median_length
    FROM {{ schema }}.{{ asset }}
    WHERE {{ text_column }} IS NOT NULL
)
SELECT
    column_name,
    total_rows,
    optimal_length_rows,
    too_short_rows,
    too_long_rows,
    ROUND(avg_length, 0) AS avg_char_length,
    ROUND(median_length::NUMERIC, 0) AS median_char_length,
    optimal_length_rows::NUMERIC / NULLIF(total_rows::NUMERIC, 0) AS value
FROM text_stats
```
