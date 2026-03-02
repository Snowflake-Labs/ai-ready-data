CREATE OR REPLACE TABLE {{ database }}.{{ schema }}.{{ asset }} AS
SELECT *
FROM {{ database }}.{{ schema }}.{{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} DESC) = 1
