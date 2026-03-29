# Diagnostic: referential_integrity

Fraction of foreign-key or cross-dataset reference values that successfully resolve to valid target records.

## Context

Lists individual orphan records — rows where the FK column has a non-null value that does not exist in the target table. Results are capped at 100 rows and sorted by FK value for review.

Foreign key constraints in Snowflake are not enforced — they are metadata hints. This diagnostic surfaces the actual orphaned rows so you can decide whether to fix or investigate further.

## SQL

```sql
-- diagnostic-referential-integrity.sql
-- Lists foreign key values that don't resolve to valid target records
-- Returns: orphan records with FK details

SELECT
    source.{{ key_columns }} AS source_key,
    source.{{ fk_column }} AS fk_value,
    'ORPHAN' AS integrity_status,
    'FK value does not exist in target table' AS issue
FROM {{ database }}.{{ schema }}.{{ asset }} source
LEFT JOIN {{ database }}.{{ target_namespace }}.{{ target_asset }} target
    ON source.{{ fk_column }} = target.{{ target_key }}
WHERE target.{{ target_key }} IS NULL
    AND source.{{ fk_column }} IS NOT NULL
ORDER BY source.{{ fk_column }}
LIMIT 100
```