# Fix: value_range_validity

Bring out-of-range numeric values back within declared boundaries.

## Context

Three options with different tradeoffs:
- **Clamping** caps values at the declared min/max boundaries. The row is preserved but the value is changed. Prefer this when the data is recoverable and the clamped value is still meaningful.
- **Deletion** removes entire rows with out-of-range values and is irreversible. Use only when out-of-range values indicate the entire record is unreliable.
- **CHECK constraint** adds a schema-level enforcement. PostgreSQL enforces CHECK constraints on every INSERT and UPDATE — this prevents future out-of-range values from entering the table.

Clamping changes data values — verify business rules before applying. Deletion is irreversible — prefer clamping for recoverable data.

## Remediation: Clamp out-of-range values (preferred — preserves rows)

```sql
UPDATE {{ schema }}.{{ asset }}
SET {{ column }} = CASE
    WHEN {{ column }} < {{ min_value }} THEN {{ min_value }}
    WHEN {{ column }} > {{ max_value }} THEN {{ max_value }}
    ELSE {{ column }}
END
WHERE {{ column }} < {{ min_value }} OR {{ column }} > {{ max_value }}
```

## Remediation: Delete out-of-range rows (irreversible)

```sql
DELETE FROM {{ schema }}.{{ asset }}
WHERE {{ column }} < {{ min_value }} OR {{ column }} > {{ max_value }}
```

## Remediation: Add CHECK constraint (prevent future violations)

After clamping or deleting out-of-range values, add a CHECK constraint to enforce the range going forward. PostgreSQL enforces this on every INSERT and UPDATE.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_{{ column }}_range
CHECK ({{ column }} >= {{ min_value }} AND {{ column }} <= {{ max_value }})
```
