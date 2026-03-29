# Fix: data_completeness

Remediation strategies for columns with null values.

## Context

There are four remediation approaches, each with different tradeoffs. Choose based on the column's semantics and downstream use:

- **Fill default** — Replace nulls with a domain-appropriate default (e.g., `0` for numeric, `''` for string). Best when the column has a natural zero/empty state. Risk: silent data loss if the default is semantically meaningful.
- **Fill placeholder** — Replace nulls with an explicit sentinel (e.g., `'UNKNOWN'`, `-1`). Best for categorical columns where downstream consumers can filter on the sentinel. Risk: placeholder values can leak into aggregations or model features if not excluded.
- **Delete incomplete** — Remove entire rows where the column is null. Best when the row is meaningless without the value (e.g., a fact table missing its measure). Risk: data loss — verify row counts before and after.
- **Add NOT NULL constraint** — Enforce non-nullability at the schema level going forward. This will fail if any nulls still exist in the column, so always run one of the above remediations first. This is a structural guard, not a data fix.

### Remediation: fill-default

Replace nulls with a concrete default value. Set `{{ default_value }}` to the appropriate literal for the column's data type.

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = {{ default_value }}
WHERE {{ column }} IS NULL
```

### Remediation: fill-placeholder

Replace nulls with a placeholder expression. Set `{{ placeholder_expression }}` to a sentinel like `'UNKNOWN'`, `'N/A'`, or `-1` depending on the column type and consumer expectations.

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = {{ placeholder_expression }}
WHERE {{ column }} IS NULL
```

### Remediation: delete-incomplete

Delete rows where the column is null. Use when the row has no value without this column. Always check `SELECT COUNT(*) ... WHERE {{ column }} IS NULL` first to understand the blast radius.

```sql
DELETE FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NULL
```

### Remediation: add-not-null

Add a NOT NULL constraint to prevent future nulls. This will fail if any nulls currently exist — run a fill or delete remediation first.

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ALTER COLUMN {{ column }} SET NOT NULL
```
