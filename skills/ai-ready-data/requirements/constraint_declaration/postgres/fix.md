# Fix: constraint_declaration

Add explicit constraints to unconstrained columns.

## Context

PostgreSQL **enforces all constraints** at write time, unlike Snowflake where key constraints are metadata-only hints.

**NOT NULL**: Before applying, ensure the column contains no NULL values — the ALTER will fail if NULLs exist. Use the diagnostic query to identify nullable columns, then backfill or delete NULLs before applying.

**Key constraints** (PRIMARY KEY, UNIQUE, FOREIGN KEY): These are fully enforced. Adding a PRIMARY KEY will fail if the column contains duplicate or NULL values. Adding a UNIQUE constraint will fail if duplicates exist. Adding a FOREIGN KEY will fail if orphan values exist. Verify data integrity before applying.

**CHECK constraints**: PostgreSQL also supports native CHECK constraints for arbitrary validation rules (e.g., `amount > 0`). These are not available in Snowflake.

## SQL

### Add NOT NULL

Use when the column should never contain NULLs and you have confirmed no NULLs currently exist.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ALTER COLUMN {{ column }} SET NOT NULL;
```

### Add Key Constraint

Use to declare primary key, unique, or foreign key constraints. All are enforced.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} {{ constraint_type }} ({{ column }});
```

### Add CHECK Constraint

Use to enforce domain-specific validation rules on column values.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} CHECK ({{ condition }});
```
