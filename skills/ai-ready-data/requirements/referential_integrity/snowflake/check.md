# Check: referential_integrity

Fraction of foreign-key or cross-dataset reference values that successfully resolve to valid target records.

## Context

Performs a LEFT JOIN from the source table's FK column to the target table's key column and counts how many source rows have no matching target. A score of 1.0 means every non-null FK value resolves successfully (no orphans).

Foreign key constraints in Snowflake are not enforced — they are metadata hints. This check validates actual referential integrity by querying the data directly.

## SQL

```sql
-- check-referential-integrity.sql
-- Checks fraction of foreign key values that resolve to valid target records
-- Returns: value (float 0-1) - fraction of FK values resolving to valid targets (1.0 = no orphans)

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
    1.0 - (orphan_rows::FLOAT / NULLIF(total_rows::FLOAT, 0)) AS value
FROM fk_check
```