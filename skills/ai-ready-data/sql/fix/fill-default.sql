UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = {{ default_value }}
WHERE {{ column }} IS NULL
