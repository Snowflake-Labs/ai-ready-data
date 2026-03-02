-- check-referential-integrity.sql
-- Checks fraction of foreign key values that resolve to valid target records
-- Returns: value (float 0-1) - fraction of FK values with missing references (lower is better)

WITH fk_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(target.{{ target_key }} IS NULL AND source.{{ fk_column }} IS NOT NULL) AS orphan_rows
    FROM {{ database }}.{{ schema }}.{{ asset }} source
    LEFT JOIN {{ database }}.{{ target_namespace }}.{{ target_asset }} target
        ON source.{{ fk_column }} = target.{{ target_key }}
)
SELECT
    orphan_rows,
    total_rows,
    orphan_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM fk_check
