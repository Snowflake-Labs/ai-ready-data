-- check-schema-conformity.sql
-- Returns: value (float 0-1) - fraction of columns with correct data types
-- Returns: value (float 0-1) - fraction of columns with correct data types (1.0 = all conform)

WITH declared_types AS (
    SELECT 
        table_name,
        column_name,
        data_type,
        is_nullable
    FROM {{ database }}.information_schema.columns
    WHERE table_schema = '{{ schema }}'
        AND table_name = '{{ asset }}'
),
type_violations AS (
    SELECT COUNT(*) AS cnt
    FROM declared_types
    WHERE 
        -- Flag columns with overly permissive types
        (data_type = 'VARIANT' AND column_name NOT LIKE '%JSON%' AND column_name NOT LIKE '%PAYLOAD%')
        OR (data_type = 'VARCHAR' AND column_name LIKE '%_ID' AND column_name NOT LIKE '%UUID%')
        OR (data_type = 'VARCHAR' AND (column_name LIKE '%_DATE' OR column_name LIKE '%_AT' OR column_name LIKE '%_TIME'))
        OR (data_type = 'FLOAT' AND (column_name LIKE '%_COUNT' OR column_name LIKE '%_QTY' OR column_name LIKE '%_QUANTITY'))
),
total AS (
    SELECT COUNT(*) AS cnt FROM declared_types
)
SELECT
    total.cnt - type_violations.cnt AS conforming_columns,
    total.cnt AS total_columns,
    (total.cnt - type_violations.cnt)::FLOAT / NULLIF(total.cnt::FLOAT, 0) AS value
FROM type_violations, total
