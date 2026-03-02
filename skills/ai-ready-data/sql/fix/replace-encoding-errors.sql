UPDATE {{ container }}.{{ namespace }}.{{ asset }}
SET {{ field }} = REGEXP_REPLACE(
    REPLACE(
        REPLACE({{ field }}, CHR(65533), ''),
        CHR(0), ''
    ),
    '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]', ''
)
WHERE {{ field }} LIKE '%' || CHR(65533) || '%'
    OR {{ field }} LIKE '%' || CHR(0) || '%'
    OR REGEXP_COUNT({{ field }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') > 0
