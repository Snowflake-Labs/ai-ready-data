# Fix: relationship_declaration

Add explicit foreign key constraints to declare cross-entity relationships.

## Context

PostgreSQL foreign key constraints are **enforced** — inserts or updates that violate referential integrity will be rejected. Before adding a foreign key, verify that all existing values in the referencing column exist in the referenced table's target column.

Use the diagnostic query to identify columns with `NO_FK` status, then declare foreign keys for legitimate cross-entity references.

## SQL

### Add a foreign key constraint

```sql
ALTER TABLE {{ schema }}.{{ table }}
ADD CONSTRAINT {{ constraint_name }}
FOREIGN KEY ({{ column }})
REFERENCES {{ schema }}.{{ referenced_table }} ({{ referenced_column }});
```

### Identify orphan values before adding FK

Run this before adding the constraint to find values that would violate it.

```sql
SELECT DISTINCT t.{{ column }}
FROM {{ schema }}.{{ table }} t
WHERE t.{{ column }} IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM {{ schema }}.{{ referenced_table }} r
      WHERE r.{{ referenced_column }} = t.{{ column }}
  );
```
