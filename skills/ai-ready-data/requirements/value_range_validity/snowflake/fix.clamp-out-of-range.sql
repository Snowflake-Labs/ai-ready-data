UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = CASE
    WHEN {{ column }} < {{ min_value }} THEN {{ min_value }}
    WHEN {{ column }} > {{ max_value }} THEN {{ max_value }}
    ELSE {{ column }}
END
WHERE {{ column }} < {{ min_value }} OR {{ column }} > {{ max_value }}
