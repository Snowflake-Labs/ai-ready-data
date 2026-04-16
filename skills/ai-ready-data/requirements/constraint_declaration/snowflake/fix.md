# Fix: constraint_declaration

Add explicit constraints to unconstrained columns.

## Context

Two remediation paths are available depending on the type of constraint needed.

**NOT NULL** is the only constraint Snowflake enforces at write time. Before applying it, ensure the column contains no NULL values — the ALTER will fail if NULLs exist. Use the diagnostic query to identify nullable columns, then backfill or delete NULLs before applying.

**Key constraints** (PRIMARY KEY, UNIQUE, FOREIGN KEY) are declarative metadata hints in Snowflake — they are **not enforced**. Adding them will not reject invalid data, but they signal intent to query optimizers, BI tools, and AI systems that consume schema metadata. The `{{ constraint_name }}` should be a descriptive identifier (e.g., `pk_orders_order_id`), and `{{ constraint_type }}` should be one of `PRIMARY KEY`, `UNIQUE`, or `FOREIGN KEY`.

Snowflake does not support `ADD CONSTRAINT IF NOT EXISTS` and will error if a constraint of the same name already exists. Before applying the key-constraint fix below, run the idempotency guard and skip the ALTER if a row is returned:

```sql
SELECT 1
FROM {{ database }}.information_schema.table_constraints
WHERE UPPER(constraint_schema) = UPPER('{{ schema }}')
  AND UPPER(table_name) = UPPER('{{ asset }}')
  AND UPPER(constraint_name) = UPPER('{{ constraint_name }}');
```

### Add NOT NULL

Use when the column should never contain NULLs and you have confirmed no NULLs currently exist. `ALTER COLUMN SET NOT NULL` is a no-op if the column is already NOT NULL, so no guard is needed.

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ALTER COLUMN {{ column }} SET NOT NULL
```

### Add Key Constraint

Use to declare primary key, unique, or foreign key constraints as metadata hints. Run the idempotency guard above first. `{{ key_columns }}` is a comma-separated list (e.g. `order_id` or `order_id, line_number`).

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} {{ constraint_type }} ({{ key_columns }})
```
