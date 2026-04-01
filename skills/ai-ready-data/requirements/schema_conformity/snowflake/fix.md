# Fix: schema_conformity

Remediation guidance for columns with type mismatches.

## Context

Schema conformity issues are type-mismatch warnings — the column's declared type is overly permissive or inconsistent with its naming convention. Fixes involve altering the column type, which requires validating that existing data can safely convert. Use TRY_TO_NUMBER, TRY_TO_DATE, and TRY_TO_TIMESTAMP to verify conversion safety before altering.

## Fix: Validate and alter column types

Before changing any column type, run a validation query to confirm all existing values convert cleanly. Then alter the column.

### Validate conversion safety

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(TRY_TO_NUMBER({{ column }})) AS convertible_to_number,
    COUNT(TRY_TO_DATE({{ column }})) AS convertible_to_date,
    COUNT(TRY_TO_TIMESTAMP({{ column }})) AS convertible_to_timestamp
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```

### Alter column type (after validation)

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
    ALTER COLUMN {{ column }} SET DATA TYPE {{ expected_type }};
```
