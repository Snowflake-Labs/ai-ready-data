-- diagnostic-schema-conformity.sql
-- Returns: columns with potential type mismatches

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    CASE
        WHEN data_type = 'VARIANT' AND column_name NOT LIKE '%JSON%' AND column_name NOT LIKE '%PAYLOAD%'
            THEN 'VARIANT may be too permissive - consider structured type'
        WHEN data_type = 'VARCHAR' AND column_name LIKE '%_ID' AND column_name NOT LIKE '%UUID%'
            THEN 'ID column stored as VARCHAR - consider NUMBER or UUID'
        WHEN data_type = 'VARCHAR' AND (column_name LIKE '%_DATE' OR column_name LIKE '%_AT' OR column_name LIKE '%_TIME')
            THEN 'Date/time column stored as VARCHAR - consider TIMESTAMP'
        WHEN data_type = 'FLOAT' AND (column_name LIKE '%_COUNT' OR column_name LIKE '%_QTY' OR column_name LIKE '%_QUANTITY')
            THEN 'Count column stored as FLOAT - consider INTEGER'
        ELSE 'Review type appropriateness'
    END AS issue
FROM {{ container }}.information_schema.columns
WHERE table_schema = '{{ namespace }}'
    AND table_name = '{{ asset }}'
    AND (
        (data_type = 'VARIANT' AND column_name NOT LIKE '%JSON%' AND column_name NOT LIKE '%PAYLOAD%')
        OR (data_type = 'VARCHAR' AND column_name LIKE '%_ID' AND column_name NOT LIKE '%UUID%')
        OR (data_type = 'VARCHAR' AND (column_name LIKE '%_DATE' OR column_name LIKE '%_AT' OR column_name LIKE '%_TIME'))
        OR (data_type = 'FLOAT' AND (column_name LIKE '%_COUNT' OR column_name LIKE '%_QTY' OR column_name LIKE '%_QUANTITY'))
    )
ORDER BY table_name, column_name
