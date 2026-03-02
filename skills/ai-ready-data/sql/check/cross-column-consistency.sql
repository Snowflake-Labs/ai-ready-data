-- check-cross-column-consistency.sql
-- Checks fraction of records where related columns are mutually consistent
-- Returns: value (float 0-1) - fraction of inconsistent records (lower is better)

-- This is a template - customize the consistency_rule for your use case
-- Example rules:
--   - end_date >= start_date
--   - total = quantity * unit_price
--   - status = 'SHIPPED' implies shipped_date IS NOT NULL

WITH consistency_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(NOT ({{ consistency_rule }})) AS inconsistent_rows
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ filter_nulls }}
)
SELECT
    inconsistent_rows,
    total_rows,
    inconsistent_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM consistency_check
