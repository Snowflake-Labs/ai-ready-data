# Diagnostic: cross_column_consistency

Lists records that violate a cross-column consistency rule, with the offending column values and rule description.

## Context

Returns up to 100 rows that fail the consistency rule, showing the key columns, both column values, and the rule that was violated. Use this after a check score below 1.0 to identify which specific records need correction.

The agent must supply `consistency_rule`, `filter_nulls`, `key_columns`, `column1`, `column2`, and `rule_description` for each use case. `consistency_rule` and `filter_nulls` are injected as raw SQL expressions. `rule_description` is injected as a string literal label describing the rule being tested.

## SQL

```sql
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
```