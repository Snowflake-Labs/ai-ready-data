# Check: syntactic_validity

Fraction of raw data records that parse without structural errors, including well-formed serialization and correct delimiters.

## Context

JSON validity uses TRY_PARSE_JSON which returns NULL for invalid JSON. NULL values in the source column are counted as valid (they represent missing data, not malformed data). Use for VARIANT columns or VARCHAR columns containing JSON.

A score of 1.0 means every non-null value in the column parses as valid JSON.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN TRY_PARSE_JSON({{ column }}) IS NOT NULL OR {{ column }} IS NULL
        THEN 1 ELSE 0 
    END) AS valid_rows,
    SUM(CASE 
        WHEN TRY_PARSE_JSON({{ column }}) IS NOT NULL OR {{ column }} IS NULL
        THEN 1 ELSE 0 
    END)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
```