# Fix: schema_conformity

Remediation guidance for columns with type mismatches.

## Context

Schema conformity issues are type-mismatch warnings — the column's declared type is overly permissive or inconsistent with its naming convention. Fixes involve altering the column type, which requires validating that existing data can safely convert. Use TRY_TO_NUMBER, TRY_TO_DATE, and TRY_TO_TIMESTAMP to verify conversion safety before altering.

**Snowflake restricts `ALTER COLUMN SET DATA TYPE`**: within `VARCHAR`/`TEXT`/`STRING`, length can be **increased** (narrowed precision is rejected); within `NUMBER`/`DECIMAL`, precision can be **increased** but scale cannot be changed; and conversions across type families (e.g. `VARCHAR` → `TIMESTAMP_NTZ`) are **not supported** in place. For those cases, the remediation is:

1. Add a new column with the target type.
2. Populate it via `UPDATE ... SET new_col = TRY_TO_TIMESTAMP(old_col)` (or the equivalent `TRY_TO_*`).
3. Verify the conversion covered every row.
4. Drop the old column and rename the new one, or keep both and update downstream consumers.

Always run the validation query first — if any `TRY_TO_*` call returns NULL for non-NULL source values, those rows will lose data.

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
