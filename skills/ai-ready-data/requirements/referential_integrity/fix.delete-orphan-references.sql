DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ fk_column }} NOT IN (
    SELECT {{ target_key }}
    FROM {{ database }}.{{ target_namespace }}.{{ target_asset }}
)
