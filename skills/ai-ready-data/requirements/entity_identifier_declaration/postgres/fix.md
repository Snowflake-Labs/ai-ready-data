# Fix: entity_identifier_declaration

Guidance for declaring entity identifiers on tables that lack them.

## Context

PostgreSQL primary key and unique constraints are **enforced** at write time. Adding a primary key imposes a runtime uniqueness and non-null check — inserts that violate the constraint will be rejected. Before adding a primary key, verify that the column(s) contain no duplicates or NULLs.

Choose the column(s) that uniquely identify each row. If no single column is sufficient, use a composite key. Prefer `PRIMARY KEY` over `UNIQUE` when the column(s) represent the main entity identifier.

## SQL

### Add a primary key on a single column

```sql
ALTER TABLE {{ schema }}.{{ table }} ADD PRIMARY KEY ({{ column }});
```

### Add a primary key on multiple columns (composite key)

```sql
ALTER TABLE {{ schema }}.{{ table }} ADD PRIMARY KEY ({{ column1 }}, {{ column2 }});
```

### Add a unique constraint instead (when PK is not appropriate)

```sql
ALTER TABLE {{ schema }}.{{ table }} ADD UNIQUE ({{ column }});
```
