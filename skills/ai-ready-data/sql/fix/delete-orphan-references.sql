DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} NOT IN (
    SELECT {{ column }}
    FROM {{ database }}.{{ schema }}.{{ reference_table }}
)
