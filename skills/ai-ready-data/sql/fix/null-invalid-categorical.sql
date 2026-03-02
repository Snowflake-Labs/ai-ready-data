UPDATE {{ container }}.{{ namespace }}.{{ asset }}
SET {{ field }} = NULL
WHERE {{ field }} IS NOT NULL
    AND {{ field }} NOT IN ({{ allowed_values }})
