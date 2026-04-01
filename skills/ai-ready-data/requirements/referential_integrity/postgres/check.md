# Check: referential_integrity

Fraction of foreign-key or cross-dataset reference values that successfully resolve to valid target records.

## Context

Performs a LEFT JOIN from the source table's FK column to the target table's key column and counts how many source rows have no matching target. A score of 1.0 means every non-null FK value resolves successfully (no orphans).

PostgreSQL enforces foreign key constraints — if an FK constraint exists, orphan rows cannot be created. This check is useful for:
- **Soft references** (no FK constraint) where referential integrity is maintained by convention, not enforcement.
- **Cross-schema references** where FK constraints may not be practical.
- **Validating data before adding an FK constraint.**

## SQL

```sql
WITH fk_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE target.{{ target_key }} IS NULL AND source.{{ fk_column }} IS NOT NULL) AS orphan_rows
    FROM {{ schema }}.{{ asset }} source
    LEFT JOIN {{ target_schema }}.{{ target_asset }} target
        ON source.{{ fk_column }} = target.{{ target_key }}
)
SELECT
    orphan_rows,
    total_rows,
    1.0 - (orphan_rows::NUMERIC / NULLIF(total_rows::NUMERIC, 0)) AS value
FROM fk_check
```
