DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} < {{ min_value }} OR {{ column }} > {{ max_value }}
