# Check: syntactic_validity

Fraction of records whose value in the target column parses as valid JSON.

## Context

Uses `TRY_PARSE_JSON`, which returns NULL for inputs that cannot be parsed. NULL source values are excluded from both the numerator and denominator — a missing value is neither a valid nor an invalid JSON document.

Note: any well-formed JSON literal will parse, including scalars like `42` or `"hello"`. Only run this check on columns that are **intended** to hold JSON documents (VARIANT columns, or VARCHAR/TEXT columns whose contract is "serialized JSON"). Pointing it at arbitrary text will produce inflated scores whenever values happen to be valid JSON scalars.

A score of 1.0 means every non-null value parses as JSON.

## SQL

```sql
WITH col_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(TRY_PARSE_JSON({{ column }}) IS NOT NULL) AS valid_rows
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
)
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    total_rows,
    valid_rows,
    valid_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM col_check
```
