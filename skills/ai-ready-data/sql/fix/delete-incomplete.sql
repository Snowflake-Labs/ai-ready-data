DELETE FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NULL
