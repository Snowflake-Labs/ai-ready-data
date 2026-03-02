-- diagnostic-temporal-referential-integrity.sql
-- Shows timestamp validity issues in a table
-- Returns: records with invalid or suspicious timestamps

SELECT
    {{ key_columns }},
    {{ timestamp_column }} AS timestamp_value,
    CASE
        WHEN {{ timestamp_column }} IS NULL THEN 'NULL_TIMESTAMP'
        WHEN {{ timestamp_column }} > CURRENT_TIMESTAMP() THEN 'FUTURE_TIMESTAMP'
        WHEN {{ timestamp_column }} < '1900-01-01'::TIMESTAMP THEN 'ANCIENT_TIMESTAMP'
        WHEN {{ timestamp_column }} = '1970-01-01'::TIMESTAMP THEN 'EPOCH_TIMESTAMP'
        ELSE 'VALID'
    END AS timestamp_status,
    CASE
        WHEN {{ timestamp_column }} IS NULL THEN 'Missing event timestamp'
        WHEN {{ timestamp_column }} > CURRENT_TIMESTAMP() THEN 'Timestamp in future - possible data entry error'
        WHEN {{ timestamp_column }} < '1900-01-01'::TIMESTAMP THEN 'Unrealistic date - likely default/placeholder'
        WHEN {{ timestamp_column }} = '1970-01-01'::TIMESTAMP THEN 'Unix epoch - likely uninitialized'
        ELSE 'Valid timestamp'
    END AS recommendation
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ timestamp_column }} IS NULL
    OR {{ timestamp_column }} > CURRENT_TIMESTAMP()
    OR {{ timestamp_column }} < '1900-01-01'::TIMESTAMP
    OR {{ timestamp_column }} = '1970-01-01'::TIMESTAMP
ORDER BY {{ timestamp_column }} NULLS FIRST
LIMIT 100
