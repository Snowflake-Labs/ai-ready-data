# Fix: referential_integrity

Remediation strategies for orphan foreign-key references.

## Context

PostgreSQL enforces FK constraints — unlike Snowflake where they are metadata hints. Two remediation approaches plus an enforcement option:

- **Delete orphan references** — Remove rows whose FK value does not exist in the target table. Irreversible — verify orphan records are truly invalid before removing.
- **Null out orphan references** — Set the FK column to NULL for orphan rows, preserving the rest of the row data.
- **Add FK constraint** — After cleaning orphans, add a formal foreign key constraint to prevent future orphan rows. PostgreSQL enforces this on every INSERT and UPDATE.

Always run the diagnostic query first and review orphaned rows before applying any fix.

## Remediation: Delete orphan references

```sql
DELETE FROM {{ schema }}.{{ asset }}
WHERE {{ fk_column }} IS NOT NULL
    AND {{ fk_column }} NOT IN (
        SELECT {{ target_key }}
        FROM {{ target_schema }}.{{ target_asset }}
    )
```

## Remediation: Null out orphan references (preserves rows)

```sql
UPDATE {{ schema }}.{{ asset }}
SET {{ fk_column }} = NULL
WHERE {{ fk_column }} IS NOT NULL
    AND {{ fk_column }} NOT IN (
        SELECT {{ target_key }}
        FROM {{ target_schema }}.{{ target_asset }}
    )
```

## Remediation: Add FK constraint (prevent future orphans)

After cleaning orphan rows, add a foreign key constraint. PostgreSQL enforces this constraint — any INSERT or UPDATE that would create an orphan is rejected.

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_{{ fk_column }}_fk
FOREIGN KEY ({{ fk_column }}) REFERENCES {{ target_schema }}.{{ target_asset }} ({{ target_key }})
```
