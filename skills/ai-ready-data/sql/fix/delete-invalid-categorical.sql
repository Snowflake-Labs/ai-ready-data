DELETE FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NOT NULL
    AND {{ field }} NOT IN ({{ allowed_values }})
