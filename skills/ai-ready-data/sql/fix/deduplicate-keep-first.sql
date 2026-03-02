CREATE OR REPLACE TABLE {{ container }}.{{ namespace }}.{{ asset }} AS
SELECT *
FROM {{ container }}.{{ namespace }}.{{ asset }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY {{ key_columns }} ORDER BY {{ tiebreaker_column }} ASC) = 1
