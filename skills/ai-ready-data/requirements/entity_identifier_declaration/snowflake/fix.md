# Fix: entity_identifier_declaration

Guidance for declaring entity identifiers on tables that lack them.

## Context

Snowflake primary key and unique constraints are **not enforced** — they serve as metadata hints for query optimizers and downstream tools. Adding a primary key does not impose a runtime uniqueness check, so there is no risk of insert failures. However, the declared key should still reflect the true grain of the table.

Choose the column(s) that uniquely identify each row. If no single column is sufficient, use a composite key. Prefer `PRIMARY KEY` over `UNIQUE` when the column(s) represent the main entity identifier.

## SQL

```sql
-- Add a primary key on a single column
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} ADD PRIMARY KEY ({{ column }});
```

```sql
-- Add a primary key on multiple columns (composite key)
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} ADD PRIMARY KEY ({{ column1 }}, {{ column2 }});
```

```sql
-- Add a unique constraint instead (when PK is not appropriate)
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} ADD UNIQUE ({{ column }});
```
