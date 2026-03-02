-- diagnostic-cross-field-consistency.sql
-- Lists records that violate cross-field consistency rules
-- Returns: inconsistent records with rule violation details

-- Customize consistency_rule for your use case
SELECT
    {{ key_columns }},
    {{ field1 }} AS field1_value,
    {{ field2 }} AS field2_value,
    '{{ rule_description }}' AS rule,
    CASE
        WHEN NOT ({{ consistency_rule }}) THEN 'VIOLATED'
        ELSE 'CONSISTENT'
    END AS consistency_status,
    'Review and correct field values' AS recommendation
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE NOT ({{ consistency_rule }})
    AND {{ filter_nulls }}
ORDER BY {{ key_columns }}
LIMIT 100
