# Fix: categorical_validity

Remove or null-out values that don't belong to the declared allowed set.

## Context

Two options with different tradeoffs:
- **Nulling** preserves row count and is reversible (the row still exists, just with a NULL in the column). Prefer this when the row has other valuable data.
- **Deletion** removes entire rows and is irreversible. Use only when the invalid categorical value means the entire record is unusable.

In both cases, verify the allowed values list is correct and current before executing. If the "invalid" values are actually legitimate new categories, the fix is to update the allowed values list, not to remove data.

## Fix: Null invalid values (preferred — preserves rows)

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = NULL
WHERE {{ column }} IS NOT NULL
    AND {{ column }} NOT IN ({{ allowed_values }})
```

## Fix: Delete rows with invalid values (irreversible)

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND {{ column }} NOT IN ({{ allowed_values }})
```
