# Fix: schema_conformity

Remediation guidance for columns with type mismatches.

## Context

Schema conformity issues are type-mismatch warnings — the column's declared type is overly permissive or inconsistent with its naming convention. Fixes involve altering the column type using `ALTER TABLE ... ALTER COLUMN ... TYPE ... USING ...`. PostgreSQL requires a `USING` clause to specify how to cast existing data during the type change.

Before changing any column type, run a validation query to confirm all existing values convert cleanly. PostgreSQL does not have `TRY_TO_*` functions — instead, test conversion by attempting a cast in a query and checking for failures.

## Remediation: Validate and alter column types

### Validate conversion safety (numeric)

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE {{ column }} ~ '^\d+(\.\d+)?$') AS convertible_to_numeric
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```

### Validate conversion safety (date/timestamp)

```sql
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE {{ column }}::timestamp IS NOT NULL) AS convertible_to_timestamp
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```

### Alter column type (after validation)

PostgreSQL requires `USING` to specify the cast expression. This acquires an `ACCESS EXCLUSIVE` lock on the table — plan for downtime on large tables.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    ALTER COLUMN {{ column }} TYPE {{ expected_type }} USING {{ column }}::{{ expected_type }};
```
