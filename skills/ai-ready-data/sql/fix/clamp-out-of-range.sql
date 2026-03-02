UPDATE {{ container }}.{{ namespace }}.{{ asset }}
SET {{ field }} = CASE
    WHEN {{ field }} < {{ min_value }} THEN {{ min_value }}
    WHEN {{ field }} > {{ max_value }} THEN {{ max_value }}
    ELSE {{ field }}
END
WHERE {{ field }} < {{ min_value }} OR {{ field }} > {{ max_value }}
