DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NULL
