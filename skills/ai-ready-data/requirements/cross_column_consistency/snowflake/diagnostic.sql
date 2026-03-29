-- diagnostic-cross-column-consistency.sql
-- Lists records that violate cross-column consistency rules
-- Returns: inconsistent records with rule violation details

-- Customize consistency_rule for your use case
SELECT
    {{ key_columns }},
    {{ column1 }} AS column1_value,
    {{ column2 }} AS column2_value,
    '{{ rule_description }}' AS rule,
    CASE
        WHEN NOT ({{ consistency_rule }}) THEN 'VIOLATED'
        ELSE 'CONSISTENT'
    END AS consistency_status,
    'Review and correct column values' AS recommendation
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE NOT ({{ consistency_rule }})
    AND {{ filter_nulls }}
ORDER BY {{ key_columns }}
LIMIT 100
