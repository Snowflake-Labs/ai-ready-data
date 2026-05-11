# Diagnostic: temporal_referential_integrity

Per-record breakdown of timestamp validity issues.

## Context

Returns up to 100 records with invalid or suspicious timestamps, classified as `NULL_TIMESTAMP`, `FUTURE_TIMESTAMP`, `ANCIENT_TIMESTAMP` (before 1900), or `EPOCH_TIMESTAMP` (exactly 1970-01-01). Each row includes a recommendation describing the likely cause. Use this to understand the distribution of timestamp problems before deciding on a remediation strategy.

## SQL

```sql
SELECT
    {{ key_columns }},
    {{ timestamp_column }} AS timestamp_value,
    CASE
        WHEN {{ timestamp_column }} IS NULL THEN 'NULL_TIMESTAMP'
        WHEN {{ timestamp_column }} > CURRENT_TIMESTAMP THEN 'FUTURE_TIMESTAMP'
        WHEN {{ timestamp_column }} < TIMESTAMP '1900-01-01' THEN 'ANCIENT_TIMESTAMP'
        WHEN {{ timestamp_column }} = TIMESTAMP '1970-01-01' THEN 'EPOCH_TIMESTAMP'
        ELSE 'VALID'
    END AS timestamp_status,
    CASE
        WHEN {{ timestamp_column }} IS NULL THEN 'Missing event timestamp'
        WHEN {{ timestamp_column }} > CURRENT_TIMESTAMP THEN 'Timestamp in future - possible data entry error'
        WHEN {{ timestamp_column }} < TIMESTAMP '1900-01-01' THEN 'Unrealistic date - likely default/placeholder'
        WHEN {{ timestamp_column }} = TIMESTAMP '1970-01-01' THEN 'Unix epoch - likely uninitialized'
        ELSE 'Valid timestamp'
    END AS recommendation
FROM {{ schema }}.{{ asset }}
WHERE {{ timestamp_column }} IS NULL
    OR {{ timestamp_column }} > CURRENT_TIMESTAMP
    OR {{ timestamp_column }} < TIMESTAMP '1900-01-01'
    OR {{ timestamp_column }} = TIMESTAMP '1970-01-01'
ORDER BY {{ timestamp_column }} NULLS FIRST
LIMIT 100
```
