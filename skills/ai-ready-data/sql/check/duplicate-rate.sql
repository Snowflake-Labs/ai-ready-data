SELECT
    '{{ asset }}' AS table_name,
    SUM(IFF(rn > 1, 1, 0)) * 1.0 / NULLIF(COUNT(*), 0) AS value
FROM (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY 1) AS rn
    FROM {{ container }}.{{ namespace }}.{{ asset }}
)
