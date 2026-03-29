DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND {{ column }} NOT IN ({{ allowed_values }})
