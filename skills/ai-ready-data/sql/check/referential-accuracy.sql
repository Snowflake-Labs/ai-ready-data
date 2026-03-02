-- check-referential-accuracy.sql
-- Checks fraction of values verified against an authoritative reference
-- Returns: value (float 0-1) - fraction of values that don't match reference (lower is better)

-- This check compares values against a reference/lookup table
-- Use cases: ZIP code validation, currency code validation, country codes, etc.

WITH accuracy_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(
            source.{{ column }} IS NOT NULL 
            AND ref.{{ ref_column }} IS NULL
        ) AS unverified_rows
    FROM {{ container }}.{{ namespace }}.{{ asset }} source
    LEFT JOIN {{ container }}.{{ ref_namespace }}.{{ ref_asset }} ref
        ON source.{{ column }} = ref.{{ ref_column }}
)
SELECT
    unverified_rows,
    total_rows,
    unverified_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM accuracy_check
