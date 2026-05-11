# Diagnostic: referential_integrity

Lists individual orphan records — rows where the FK column has a non-null value that does not exist in the target table.

## Context

Results are capped at 100 rows and sorted by FK value for review. This diagnostic is most useful for soft references (columns without a formal FK constraint) or for validating data before adding an FK constraint.

If a formal FK constraint exists, PostgreSQL prevents orphan rows at write time, making this diagnostic unnecessary for constrained columns.

## SQL

```sql
SELECT
    source.{{ key_columns }} AS source_key,
    source.{{ fk_column }} AS fk_value,
    'ORPHAN' AS integrity_status,
    'FK value does not exist in target table' AS issue
FROM {{ schema }}.{{ asset }} source
LEFT JOIN {{ target_schema }}.{{ target_asset }} target
    ON source.{{ fk_column }} = target.{{ target_key }}
WHERE target.{{ target_key }} IS NULL
    AND source.{{ fk_column }} IS NOT NULL
ORDER BY source.{{ fk_column }}
LIMIT 100
```
