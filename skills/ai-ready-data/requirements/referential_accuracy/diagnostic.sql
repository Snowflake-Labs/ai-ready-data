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
