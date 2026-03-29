# Diagnostic: referential_accuracy

Lists source values that do not match any entry in the authoritative reference table.

## Context

Returns the distinct unverified values along with their occurrence counts, ordered by frequency. Results are capped at 100 rows to keep output manageable. Each row is flagged as `NOT_IN_REFERENCE` to indicate the value was not found in the reference table.

Placeholders: `database`, `schema`, `asset`, `column`, `ref_namespace`, `ref_asset`, `ref_column`.

## SQL

```sql
-- diagnostic-referential-accuracy.sql
-- Lists values that don't match authoritative reference
-- Returns: unverified values with details

SELECT
    source.{{ column }} AS value,
    COUNT(*) AS occurrence_count,
    'NOT_IN_REFERENCE' AS accuracy_status,
    'Value not found in reference table {{ ref_asset }}' AS issue
FROM {{ database }}.{{ schema }}.{{ asset }} source
LEFT JOIN {{ database }}.{{ ref_namespace }}.{{ ref_asset }} ref
    ON source.{{ column }} = ref.{{ ref_column }}
WHERE source.{{ column }} IS NOT NULL
    AND ref.{{ ref_column }} IS NULL
GROUP BY source.{{ column }}
ORDER BY occurrence_count DESC
LIMIT 100
```
