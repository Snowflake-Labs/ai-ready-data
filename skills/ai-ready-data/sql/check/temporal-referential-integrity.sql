-- check-temporal-referential-integrity.sql
-- Checks fraction of records with valid, non-null event timestamps
-- Returns: value (float 0-1) - fraction of records with valid timestamps

WITH timestamp_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF({{ timestamp_column }} IS NOT NULL 
            AND {{ timestamp_column }} <= CURRENT_TIMESTAMP()
            AND {{ timestamp_column }} >= '1900-01-01'::TIMESTAMP
        ) AS valid_timestamp_rows
    FROM {{ container }}.{{ namespace }}.{{ asset }}
)
SELECT
    valid_timestamp_rows,
    total_rows,
    valid_timestamp_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM timestamp_check
