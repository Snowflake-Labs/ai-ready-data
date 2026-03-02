UPDATE {{ container }}.{{ namespace }}.{{ asset }}
SET {{ field }} = {{ placeholder_expression }}
WHERE {{ field }} IS NULL
