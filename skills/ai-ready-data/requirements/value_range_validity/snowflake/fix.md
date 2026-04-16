# Fix: value_range_validity

Bring out-of-range numeric values back within declared boundaries.

## Context

Two options with different tradeoffs:
- **Clamping** caps values at the declared min/max boundaries. The row is preserved but the value is changed. Prefer this when the data is recoverable and the clamped value is still meaningful.
- **Deletion** removes entire rows with out-of-range values and is irreversible. Use only when out-of-range values indicate the entire record is unreliable.

Clamping changes data values — verify business rules before applying. Deletion is irreversible — prefer clamping for recoverable data.

## Fix: Clamp out-of-range values (preferred — preserves rows)

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = CASE
    WHEN {{ column }} < {{ min_value }} THEN {{ min_value }}
    WHEN {{ column }} > {{ max_value }} THEN {{ max_value }}
    ELSE {{ column }}
END
WHERE {{ column }} < {{ min_value }} OR {{ column }} > {{ max_value }}
```

## Fix: Delete out-of-range rows (irreversible)

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} < {{ min_value }} OR {{ column }} > {{ max_value }}
```
