# Fix: entity_identifier_declaration

Declare entity identifiers on tables that lack them.

## Context

Snowflake primary key and unique constraints are **not enforced** — they serve as metadata hints for query optimizers and downstream tools. Adding a primary key does not impose a runtime uniqueness check, so there is no risk of insert failures. However, the declared key should still reflect the true grain of the table.

Choose the column(s) that uniquely identify each row. If no single column is sufficient, use a composite key. Prefer `PRIMARY KEY` over `UNIQUE` when the column(s) represent the main entity identifier.

Before applying, check whether a constraint of the same name already exists — Snowflake rejects duplicate constraint names:

```sql
SELECT 1 FROM {{ database }}.information_schema.table_constraints
WHERE constraint_schema = '{{ schema }}'
  AND table_name = '{{ asset }}'
  AND constraint_name = '{{ constraint_name }}';
```

Skip the ALTER if this returns a row.

## Fix: Add a primary key on a single column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} PRIMARY KEY ({{ column }});
```

## Fix: Add a composite primary key

Use `{{ key_columns }}` as a comma-separated list of column names (e.g. `order_id, line_number`):

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} PRIMARY KEY ({{ key_columns }});
```

## Fix: Add a unique constraint

Use when the column is a natural key but not the main entity identifier:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
ADD CONSTRAINT {{ constraint_name }} UNIQUE ({{ column }});
```
