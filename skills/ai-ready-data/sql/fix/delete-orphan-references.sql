DELETE FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} NOT IN (
    SELECT {{ field }}
    FROM {{ container }}.{{ namespace }}.{{ reference_table }}
)
