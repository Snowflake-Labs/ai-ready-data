# Fix: categorical_validity

Remove or null-out values that don't belong to the declared allowed set.

## Context

Three options with different tradeoffs:
- **Nulling** preserves row count and is reversible (the row still exists, just with a NULL in the column). Prefer this when the row has other valuable data.
- **Deletion** removes entire rows and is irreversible. Use only when the invalid categorical value means the entire record is unusable.
- **ENUM type migration** — PostgreSQL supports native ENUM types that enforce categorical validity at the schema level. After cleaning invalid values, consider migrating the column to an ENUM type to prevent future violations.

In all cases, verify the allowed values list is correct and current before executing. If the "invalid" values are actually legitimate new categories, the fix is to update the allowed values list, not to remove data.

## Remediation: Null invalid values (preferred — preserves rows)

```sql
UPDATE {{ schema }}.{{ asset }}
SET {{ column }} = NULL
WHERE {{ column }} IS NOT NULL
    AND {{ column }} NOT IN ({{ allowed_values }})
```

## Remediation: Delete rows with invalid values (irreversible)

```sql
DELETE FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND {{ column }} NOT IN ({{ allowed_values }})
```

## Remediation: Migrate to ENUM type (prevent future violations)

Create an ENUM type and alter the column to use it. PostgreSQL enforces ENUM values on INSERT and UPDATE — any value not in the type definition is rejected.

```sql
CREATE TYPE {{ schema }}.{{ column }}_enum AS ENUM ({{ allowed_values }});

ALTER TABLE {{ schema }}.{{ asset }}
    ALTER COLUMN {{ column }} TYPE {{ schema }}.{{ column }}_enum
    USING {{ column }}::{{ schema }}.{{ column }}_enum;
```
