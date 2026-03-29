# Diagnostic: schema_conformity

Columns with potential type mismatches, with a specific issue description for each.

## Context

Lists every column in the table whose declared type conflicts with its naming convention. Each row includes a human-readable issue string explaining the mismatch (e.g., "ID column stored as VARCHAR - consider NUMBER or UUID"). Uses TRY_TO_NUMBER, TRY_TO_DATE, TRY_TO_TIMESTAMP for type checking.

Use this to identify exactly which columns need type changes and what the recommended target type is.

## SQL

```sql
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
FROM {{ database }}.information_schema.columns
WHERE table_schema = '{{ schema }}'
    AND table_name = '{{ asset }}'
    AND (
        (data_type = 'VARIANT' AND column_name NOT LIKE '%JSON%' AND column_name NOT LIKE '%PAYLOAD%')
        OR (data_type = 'VARCHAR' AND column_name LIKE '%_ID' AND column_name NOT LIKE '%UUID%')
        OR (data_type = 'VARCHAR' AND (column_name LIKE '%_DATE' OR column_name LIKE '%_AT' OR column_name LIKE '%_TIME'))
        OR (data_type = 'FLOAT' AND (column_name LIKE '%_COUNT' OR column_name LIKE '%_QTY' OR column_name LIKE '%_QUANTITY'))
    )
ORDER BY table_name, column_name
```
