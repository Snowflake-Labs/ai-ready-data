UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = NULL
WHERE {{ column }} IS NOT NULL
    AND {{ column }} NOT IN ({{ allowed_values }})
