UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = {{ placeholder_expression }}
WHERE {{ column }} IS NULL
