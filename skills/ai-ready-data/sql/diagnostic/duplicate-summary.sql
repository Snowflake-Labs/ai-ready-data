SELECT
    {{ key_columns }},
    COUNT(*) AS duplicate_count
FROM {{ container }}.{{ namespace }}.{{ asset }}
GROUP BY {{ key_columns }}
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 50
